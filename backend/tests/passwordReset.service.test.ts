import { beforeEach, describe, expect, it, vi } from 'vitest';

type StoredUser = { id: string; email: string; name: string; passwordHash: string };
type StoredToken = {
  id: string;
  userId: string;
  codeHash: string;
  expiresAt: Date;
  consumedAt: Date | null;
};

const users = new Map<string, StoredUser>();
const tokens = new Map<string, StoredToken>();
let lastMail: { to: string; subject: string; text: string } | null = null;

vi.mock('../src/repositories/userRepository.js', () => ({
  userRepository: {
    findByEmail: vi.fn(async (email: string) => {
      for (const u of users.values()) if (u.email === email) return u;
      return null;
    }),
    updatePasswordHash: vi.fn(async (id: string, passwordHash: string) => {
      const u = users.get(id);
      if (u) u.passwordHash = passwordHash;
      return u ?? null;
    }),
  },
}));

vi.mock('../src/repositories/passwordResetRepository.js', () => ({
  passwordResetRepository: {
    create: vi.fn(async (data: { userId: string; codeHash: string; expiresAt: Date }) => {
      const token: StoredToken = { id: `t_${tokens.size + 1}`, consumedAt: null, ...data };
      tokens.set(token.id, token);
      return token;
    }),
    findActiveByUser: vi.fn(async (userId: string, now: Date) => {
      let found: StoredToken | null = null;
      for (const t of tokens.values()) {
        if (t.userId === userId && t.consumedAt === null && t.expiresAt > now) found = t;
      }
      return found;
    }),
    markConsumed: vi.fn(async (id: string, consumedAt: Date) => {
      const t = tokens.get(id);
      if (t) t.consumedAt = consumedAt;
      return t ?? null;
    }),
    deleteByUser: vi.fn(async (userId: string) => {
      for (const [k, t] of tokens) if (t.userId === userId) tokens.delete(k);
      return { count: 0 };
    }),
  },
}));

vi.mock('../src/lib/mailer.js', () => ({
  sendMail: vi.fn(async (msg: { to: string; subject: string; text: string }) => {
    lastMail = msg;
  }),
}));

const { passwordResetService } = await import('../src/services/passwordResetService.js');
const { hashPassword, verifyPassword } = await import('../src/lib/password.js');

const codeFromMail = (): string => {
  const match = lastMail?.text.match(/\b(\d{6})\b/);
  if (!match) throw new Error('No reset code found in email');
  return match[1];
};

beforeEach(async () => {
  users.clear();
  tokens.clear();
  lastMail = null;
  users.set('u_1', {
    id: 'u_1',
    email: 'a@b.com',
    name: 'Alice',
    passwordHash: await hashPassword('oldpassword'),
  });
});

describe('passwordResetService.requestReset', () => {
  it('emails a 6-digit code and stores its hash for a known user', async () => {
    await passwordResetService.requestReset({ email: 'a@b.com' });
    expect(lastMail?.to).toBe('a@b.com');
    expect(codeFromMail()).toMatch(/^\d{6}$/);
    expect(tokens.size).toBe(1);
    const [token] = [...tokens.values()];
    // The raw code is never stored.
    expect(token.codeHash).not.toBe(codeFromMail());
  });

  it('is silent and stores nothing for an unknown email', async () => {
    await passwordResetService.requestReset({ email: 'nobody@b.com' });
    expect(lastMail).toBeNull();
    expect(tokens.size).toBe(0);
  });
});

describe('passwordResetService.resetPassword', () => {
  it('sets a new password with a valid code and consumes the token', async () => {
    await passwordResetService.requestReset({ email: 'a@b.com' });
    const code = codeFromMail();

    await passwordResetService.resetPassword({
      email: 'a@b.com',
      code,
      newPassword: 'brandnewpassword',
    });

    const user = users.get('u_1')!;
    expect(await verifyPassword('brandnewpassword', user.passwordHash)).toBe(true);
    const [token] = [...tokens.values()];
    expect(token.consumedAt).not.toBeNull();
  });

  it('rejects a wrong code with 400 INVALID_RESET_CODE', async () => {
    await passwordResetService.requestReset({ email: 'a@b.com' });
    await expect(
      passwordResetService.resetPassword({
        email: 'a@b.com',
        code: '000000',
        newPassword: 'brandnewpassword',
      }),
    ).rejects.toMatchObject({ status: 400, code: 'INVALID_RESET_CODE' });
  });

  it('rejects an unknown email with 400 INVALID_RESET_CODE', async () => {
    await expect(
      passwordResetService.resetPassword({
        email: 'nobody@b.com',
        code: '123456',
        newPassword: 'brandnewpassword',
      }),
    ).rejects.toMatchObject({ status: 400, code: 'INVALID_RESET_CODE' });
  });

  it('rejects an already-consumed code', async () => {
    await passwordResetService.requestReset({ email: 'a@b.com' });
    const code = codeFromMail();
    await passwordResetService.resetPassword({ email: 'a@b.com', code, newPassword: 'brandnewpassword' });

    await expect(
      passwordResetService.resetPassword({ email: 'a@b.com', code, newPassword: 'anotherpassword' }),
    ).rejects.toMatchObject({ status: 400, code: 'INVALID_RESET_CODE' });
  });
});
