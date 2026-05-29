import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';

type StoredTx = {
  id: string;
  userId: string;
  categoryId: string;
  amount: Prisma.Decimal;
  note: string | null;
  occurredAt: Date;
  recurringIncomeId: string | null;
  deletedAt: Date | null;
};

const store = new Map<string, StoredTx>();

vi.mock('../src/repositories/transactionRepository.js', () => ({
  transactionRepository: {
    findById: vi.fn(async (id: string, userId: string) => {
      const tx = store.get(id);
      if (!tx || tx.userId !== userId || tx.deletedAt) return null;
      return {
        ...tx,
        category: {
          id: tx.categoryId,
          key: 'food',
          label: 'Food',
          abbr: 'FD',
          color: '#F56B1E',
          bgTint: '#FEF0E8',
        },
      };
    }),
    softDelete: vi.fn(async (id: string, userId: string) => {
      const tx = store.get(id);
      if (!tx || tx.userId !== userId || tx.deletedAt) return { count: 0 };
      tx.deletedAt = new Date();
      return { count: 1 };
    }),
  },
}));

const { transactionService } = await import('../src/services/transactionService.js');

beforeEach(() => {
  store.clear();
});

describe('transactionService.delete', () => {
  it('soft-deletes a regular transaction', async () => {
    store.set('tx1', {
      id: 'tx1',
      userId: 'u1',
      categoryId: 'cat_food',
      amount: new Prisma.Decimal(-10),
      note: 'Coffee',
      occurredAt: new Date(),
      recurringIncomeId: null,
      deletedAt: null,
    });

    await transactionService.delete('u1', 'tx1');
    expect(store.get('tx1')!.deletedAt).toBeInstanceOf(Date);
  });

  it('rejects deleting recurring income transactions', async () => {
    store.set('tx2', {
      id: 'tx2',
      userId: 'u1',
      categoryId: 'cat_income',
      amount: new Prisma.Decimal(5200),
      note: 'Salary',
      occurredAt: new Date(),
      recurringIncomeId: 'rec_1',
      deletedAt: null,
    });

    await expect(transactionService.delete('u1', 'tx2')).rejects.toMatchObject({
      status: 403,
      code: 'RECURRING_INCOME_PROTECTED',
    });
    expect(store.get('tx2')!.deletedAt).toBeNull();
  });
});
