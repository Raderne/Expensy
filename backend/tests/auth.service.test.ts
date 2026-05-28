import { beforeEach, describe, expect, it, vi } from 'vitest';

type StoredUser = {
  id: string;
  email: string;
  name: string;
  passwordHash: string;
};

const store = new Map<string, StoredUser>();

vi.mock('../src/repositories/userRepository.js', () => ({
  userRepository: {
    findByEmail: vi.fn(async (email: string) => {
      for (const u of store.values()) if (u.email === email) return u;
      return null;
    }),
    findById: vi.fn(async (id: string) => store.get(id) ?? null),
    create: vi.fn(async (data: { email: string; passwordHash: string; name: string }) => {
      const user: StoredUser = { id: `u_${store.size + 1}`, ...data };
      store.set(user.id, user);
      return user;
    }),
  },
}));

const { authService } = await import('../src/services/authService.js');
const { AppError } = await import('../src/lib/errors.js');

beforeEach(() => {
  store.clear();
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
  it('issues new tokens from a valid refresh token', async () => {
    const signup = await authService.signup({
      email: 'a@b.com',
      password: 'password123',
      name: 'Alice',
    });
    const refreshed = await authService.refresh(signup.refreshToken);
    expect(refreshed.accessToken).toBeTypeOf('string');
    expect(refreshed.refreshToken).toBeTypeOf('string');
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
    expect(me).toEqual({ id: signup.user.id, email: 'a@b.com', name: 'Alice' });
  });

  it('throws 404 for unknown user', async () => {
    await expect(authService.me('u_missing')).rejects.toMatchObject({
      status: 404,
      code: 'USER_NOT_FOUND',
    });
  });
});
