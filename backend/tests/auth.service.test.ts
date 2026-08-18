import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';

type StoredUser = {
  id: string;
  email: string;
  name: string;
  passwordHash: string;
  openingBalance: Prisma.Decimal;
};

type StoredRefresh = {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  revokedAt: Date | null;
  replacedById: string | null;
};

const store = new Map<string, StoredUser>();
const refreshStore = new Map<string, StoredRefresh>();

vi.mock('../src/repositories/userRepository.js', () => ({
  userRepository: {
    findByEmail: vi.fn(async (email: string) => {
      for (const u of store.values()) if (u.email === email) return u;
      return null;
    }),
    findById: vi.fn(async (id: string) => store.get(id) ?? null),
    create: vi.fn(async (data: { email: string; passwordHash: string; name: string }) => {
      const user: StoredUser = {
        id: `u_${store.size + 1}`,
        ...data,
        openingBalance: new Prisma.Decimal(0),
      };
      store.set(user.id, user);
      return user;
    }),
  },
}));

vi.mock('../src/repositories/refreshTokenRepository.js', async () => {
  const { createHash } = await import('node:crypto');
  const hash = (value: string) => createHash('sha256').update(value).digest('hex');
  return {
    refreshTokenRepository: {
      hash,
      create: vi.fn(
        async (data: { id: string; userId: string; tokenHash: string; expiresAt: Date }) => {
          const row: StoredRefresh = {
            ...data,
            revokedAt: null,
            replacedById: null,
          };
          refreshStore.set(row.id, row);
          return row;
        },
      ),
      findById: vi.fn(async (id: string) => refreshStore.get(id) ?? null),
      findByTokenHash: vi.fn(async (tokenHash: string) => {
        for (const row of refreshStore.values()) if (row.tokenHash === tokenHash) return row;
        return null;
      }),
      revoke: vi.fn(async (id: string, revokedAt: Date, replacedById?: string) => {
        const row = refreshStore.get(id);
        if (!row) return null;
        row.revokedAt = revokedAt;
        if (replacedById) row.replacedById = replacedById;
        return row;
      }),
      revokeAllForUser: vi.fn(async (userId: string, revokedAt: Date) => {
        let count = 0;
        for (const row of refreshStore.values()) {
          if (row.userId === userId && row.revokedAt === null) {
            row.revokedAt = revokedAt;
            count += 1;
          }
        }
        return { count };
      }),
    },
  };
});

const { authService } = await import('../src/services/authService.js');
const { AppError } = await import('../src/lib/errors.js');

beforeEach(() => {
  store.clear();
  refreshStore.clear();
});

describe('authService.signup', () => {
  it('creates a user and returns tokens', async () => {
    const result = await authService.signup({
      email: 'a@b.com',
      password: 'password123',
      name: 'Alice',
    });
    expect(result.user).toMatchObject({ email: 'a@b.com', name: 'Alice' });
    expect(result.user.id).toBeTruthy();
    expect(result.accessToken).toBeTypeOf('string');
    expect(result.refreshToken).toBeTypeOf('string');
    expect(refreshStore.size).toBe(1);
  });

  it('rejects a duplicate email with 409 EMAIL_TAKEN', async () => {
    await authService.signup({ email: 'a@b.com', password: 'password123', name: 'Alice' });
    await expect(
      authService.signup({ email: 'a@b.com', password: 'password123', name: 'Alice2' }),
    ).rejects.toMatchObject({ status: 409, code: 'EMAIL_TAKEN' });
  });
});

describe('authService.login', () => {
  it('returns tokens for valid credentials', async () => {
    await authService.signup({ email: 'a@b.com', password: 'password123', name: 'Alice' });
    const result = await authService.login({ email: 'a@b.com', password: 'password123' });
    expect(result.user.email).toBe('a@b.com');
    expect(result.accessToken).toBeTypeOf('string');
  });

  it('rejects unknown email with 401 INVALID_CREDENTIALS', async () => {
    await expect(
      authService.login({ email: 'nobody@b.com', password: 'whatever' }),
    ).rejects.toMatchObject({ status: 401, code: 'INVALID_CREDENTIALS' });
  });

  it('rejects wrong password with 401 INVALID_CREDENTIALS', async () => {
    await authService.signup({ email: 'a@b.com', password: 'password123', name: 'Alice' });
    await expect(
      authService.login({ email: 'a@b.com', password: 'wrongpassword' }),
    ).rejects.toMatchObject({ status: 401, code: 'INVALID_CREDENTIALS' });
  });
});

describe('authService.refresh', () => {
  it('issues new tokens from a valid refresh token and rotates the session', async () => {
    const signup = await authService.signup({
      email: 'a@b.com',
      password: 'password123',
      name: 'Alice',
    });
    const [first] = [...refreshStore.values()];
    const refreshed = await authService.refresh(signup.refreshToken);
    expect(refreshed.accessToken).toBeTypeOf('string');
    expect(refreshed.refreshToken).toBeTypeOf('string');
    expect(refreshed.refreshToken).not.toBe(signup.refreshToken);
    expect(first.revokedAt).not.toBeNull();
    expect(first.replacedById).toBeTruthy();
  });

  it('rejects reuse of a rotated refresh token and revokes all sessions', async () => {
    const signup = await authService.signup({
      email: 'a@b.com',
      password: 'password123',
      name: 'Alice',
    });
    const rotated = await authService.refresh(signup.refreshToken);
    await expect(authService.refresh(signup.refreshToken)).rejects.toMatchObject({
      status: 401,
      code: 'INVALID_REFRESH',
    });
    // The replacement session is also revoked after reuse detection.
    await expect(authService.refresh(rotated.refreshToken)).rejects.toMatchObject({
      status: 401,
      code: 'INVALID_REFRESH',
    });
  });

  it('rejects a malformed refresh token', async () => {
    await expect(authService.refresh('not-a-real-jwt')).rejects.toBeInstanceOf(AppError);
  });
});

describe('authService.me', () => {
  it('returns the public user', async () => {
    const signup = await authService.signup({
      email: 'a@b.com',
      password: 'password123',
      name: 'Alice',
    });
    const me = await authService.me(signup.user.id);
    expect(me).toEqual({
      id: signup.user.id,
      email: 'a@b.com',
      name: 'Alice',
      openingBalance: 0,
    });
  });

  it('throws 404 for unknown user', async () => {
    await expect(authService.me('u_missing')).rejects.toMatchObject({
      status: 404,
      code: 'USER_NOT_FOUND',
    });
  });
});
