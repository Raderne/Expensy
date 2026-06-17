import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';

const d = (n: number | string) => new Prisma.Decimal(n);

// Captured settle() calls so we can assert what the service forwarded.
const settle = vi.fn(async () => {});
const reverse = vi.fn(async () => {});

let split: {
  id: string;
  contactId: string;
  owedAmount: Prisma.Decimal;
  settledAmount: Prisma.Decimal;
  contact: { name: string; color: string | null };
} | null;
let reimbursement: {
  id: string;
  transactionId: string | null;
  splitId: string;
  amount: Prisma.Decimal;
  split: { owedAmount: Prisma.Decimal; settledAmount: Prisma.Decimal };
} | null;

vi.mock('../src/repositories/splitRepository.js', () => ({
  splitRepository: {
    findById: vi.fn(async () => split),
    settle,
    findReimbursementById: vi.fn(async () => reimbursement),
    reverse,
  },
}));

vi.mock('../src/repositories/categoryRepository.js', () => ({
  categoryRepository: {
    findAll: vi.fn(async () => [{ id: 'cat_income', key: 'income' }]),
  },
}));

const { sharedService } = await import('../src/services/sharedService.js');

beforeEach(() => {
  settle.mockClear();
  reverse.mockClear();
  split = {
    id: 'split_1',
    contactId: 'c1',
    owedAmount: d(175),
    settledAmount: d(0),
    contact: { name: 'Brother', color: null },
  };
  reimbursement = null;
});

describe('sharedService.createReimbursement', () => {
  it('records a partial repayment and reports PARTIAL with the remaining balance', async () => {
    const result = await sharedService.createReimbursement('u1', 'split_1', { amount: 100 });
    expect(result).toEqual({ splitId: 'split_1', remaining: 75, status: 'PARTIAL' });
    expect(settle).toHaveBeenCalledOnce();
    const arg = settle.mock.calls[0]![0] as { incomeCategoryId: string; amount: Prisma.Decimal };
    expect(arg.incomeCategoryId).toBe('cat_income');
    expect(arg.amount.toNumber()).toBe(100);
  });

  it('reports SETTLED once the full amount is repaid', async () => {
    const result = await sharedService.createReimbursement('u1', 'split_1', { amount: 175 });
    expect(result).toEqual({ splitId: 'split_1', remaining: 0, status: 'SETTLED' });
  });

  it('rejects an overpayment with 400', async () => {
    split!.settledAmount = d(100);
    await expect(
      sharedService.createReimbursement('u1', 'split_1', { amount: 100 }),
    ).rejects.toMatchObject({ status: 400, code: 'REIMBURSEMENT_EXCEEDS_OWED' });
    expect(settle).not.toHaveBeenCalled();
  });

  it('rejects an unknown split with 404', async () => {
    split = null;
    await expect(
      sharedService.createReimbursement('u1', 'missing', { amount: 10 }),
    ).rejects.toMatchObject({ status: 404, code: 'SPLIT_NOT_FOUND' });
  });
});

describe('sharedService.deleteReimbursement', () => {
  it('reverses an existing reimbursement', async () => {
    reimbursement = {
      id: 'r1',
      transactionId: 'tx1',
      splitId: 'split_1',
      amount: d(100),
      split: { owedAmount: d(175), settledAmount: d(100) },
    };
    await sharedService.deleteReimbursement('u1', 'r1');
    expect(reverse).toHaveBeenCalledOnce();
  });

  it('throws 404 for an unknown reimbursement', async () => {
    reimbursement = null;
    await expect(sharedService.deleteReimbursement('u1', 'missing')).rejects.toMatchObject({
      status: 404,
      code: 'REIMBURSEMENT_NOT_FOUND',
    });
  });
});
