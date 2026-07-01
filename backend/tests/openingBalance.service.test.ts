import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';

let stored = new Prisma.Decimal(0);

vi.mock('../src/repositories/userRepository.js', () => ({
  userRepository: {
    updateOpeningBalance: vi.fn(async (_id: string, amount: number) => {
      stored = new Prisma.Decimal(amount);
      return { id: 'u1', email: 'a@b.com', name: 'Alice', openingBalance: stored };
    }),
  },
}));

const { userService } = await import('../src/services/userService.js');
const { updateOpeningBalanceSchema } = await import('../src/schemas/user.js');

beforeEach(() => {
  stored = new Prisma.Decimal(0);
});

describe('userService.updateOpeningBalance', () => {
  it('persists the amount and returns it as a number', async () => {
    const result = await userService.updateOpeningBalance('u1', 100000);
    expect(result).toEqual({ openingBalance: 100000 });
  });

  it('supports a negative (overdraft) balance', async () => {
    const result = await userService.updateOpeningBalance('u1', -250.5);
    expect(result).toEqual({ openingBalance: -250.5 });
  });
});

describe('updateOpeningBalanceSchema', () => {
  it('accepts positive, negative, and zero amounts', () => {
    expect(updateOpeningBalanceSchema.parse({ amount: 100000 }).amount).toBe(100000);
    expect(updateOpeningBalanceSchema.parse({ amount: -500 }).amount).toBe(-500);
    expect(updateOpeningBalanceSchema.parse({ amount: 0 }).amount).toBe(0);
  });

  it('rejects non-finite and out-of-range amounts', () => {
    expect(() => updateOpeningBalanceSchema.parse({ amount: Number.NaN })).toThrow();
    expect(() => updateOpeningBalanceSchema.parse({ amount: 2_000_000_000 })).toThrow();
    expect(() => updateOpeningBalanceSchema.parse({ amount: 'lots' })).toThrow();
  });
});
