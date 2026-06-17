import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { splitRepository } from '../repositories/splitRepository.js';

export interface ReimbursementDto {
  id: string;
  amount: number;
  occurredAt: string;
}

export interface OwedSplitDto {
  splitId: string;
  expenseId: string;
  label: string;
  occurredAt: string;
  categoryKey: string;
  categoryColor: string;
  owedAmount: number;
  settledAmount: number;
  remaining: number;
  status: 'OWED' | 'PARTIAL' | 'SETTLED';
  reimbursements: ReimbursementDto[];
}

export interface OwedContactDto {
  contactId: string;
  contactName: string;
  contactColor: string | null;
  outstanding: number;
  splits: OwedSplitDto[];
}

export interface OwedOverviewDto {
  totalOutstanding: number;
  contacts: OwedContactDto[];
}

const round2 = (n: number): number => Math.round(n * 100) / 100;

const getIncomeCategoryId = async (): Promise<string> => {
  const categories = await categoryRepository.findAll();
  const income = categories.find((c) => c.key === 'income');
  if (!income) {
    throw new AppError({
      status: 500,
      code: 'INCOME_CATEGORY_MISSING',
      message: 'Income category is not configured',
    });
  }
  return income.id;
};

export const sharedService = {
  // "Who owes me": outstanding splits grouped per contact, with repayment history.
  async owed(userId: string): Promise<OwedOverviewDto> {
    const rows = await splitRepository.findOutstanding(userId);

    const byContact = new Map<string, OwedContactDto>();
    let totalOutstanding = 0;

    for (const row of rows) {
      const owed = row.owedAmount.toNumber();
      const settled = row.settledAmount.toNumber();
      const remaining = round2(Math.max(0, owed - settled));
      totalOutstanding += remaining;

      let group = byContact.get(row.contactId);
      if (!group) {
        group = {
          contactId: row.contactId,
          contactName: row.contact.name,
          contactColor: row.contact.color,
          outstanding: 0,
          splits: [],
        };
        byContact.set(row.contactId, group);
      }

      group.outstanding = round2(group.outstanding + remaining);
      group.splits.push({
        splitId: row.id,
        expenseId: row.transactionId,
        label: row.transaction.note ?? row.transaction.category.label,
        occurredAt: row.transaction.occurredAt.toISOString(),
        categoryKey: row.transaction.category.key,
        categoryColor: row.transaction.category.color,
        owedAmount: owed,
        settledAmount: settled,
        remaining,
        status: row.status as 'OWED' | 'PARTIAL' | 'SETTLED',
        reimbursements: row.reimbursements.map((r) => ({
          id: r.id,
          amount: r.amount.toNumber(),
          occurredAt: r.occurredAt.toISOString(),
        })),
      });
    }

    const contacts = [...byContact.values()].sort((a, b) => b.outstanding - a.outstanding);
    return { totalOutstanding: round2(totalOutstanding), contacts };
  },

  // Record a (partial) repayment toward a split.
  async createReimbursement(
    userId: string,
    splitId: string,
    input: { amount: number; occurredAt?: string },
  ): Promise<{ splitId: string; remaining: number; status: 'OWED' | 'PARTIAL' | 'SETTLED' }> {
    const split = await splitRepository.findById(splitId, userId);
    if (!split) {
      throw new AppError({ status: 404, code: 'SPLIT_NOT_FOUND', message: 'Split not found' });
    }

    const amount = new Prisma.Decimal(input.amount);
    const newSettled = split.settledAmount.plus(amount);
    if (newSettled.greaterThan(split.owedAmount)) {
      throw new AppError({
        status: 400,
        code: 'REIMBURSEMENT_EXCEEDS_OWED',
        message: 'Repayment exceeds the amount owed for this split',
      });
    }

    const incomeCategoryId = await getIncomeCategoryId();
    await splitRepository.settle({
      userId,
      splitId,
      contactId: split.contactId,
      incomeCategoryId,
      note: `Reimbursement · ${split.contact.name}`,
      amount,
      owedAmount: split.owedAmount,
      currentSettled: split.settledAmount,
      occurredAt: input.occurredAt ? new Date(input.occurredAt) : new Date(),
    });

    const remaining = round2(Math.max(0, split.owedAmount.minus(newSettled).toNumber()));
    const status = newSettled.greaterThanOrEqualTo(split.owedAmount) ? 'SETTLED' : 'PARTIAL';
    return { splitId, remaining, status };
  },

  // Reverse a previously-recorded repayment.
  async deleteReimbursement(userId: string, reimbursementId: string): Promise<void> {
    const reimbursement = await splitRepository.findReimbursementById(reimbursementId, userId);
    if (!reimbursement) {
      throw new AppError({
        status: 404,
        code: 'REIMBURSEMENT_NOT_FOUND',
        message: 'Reimbursement not found',
      });
    }

    await splitRepository.reverse({
      reimbursementId,
      userId,
      transactionId: reimbursement.transactionId,
      splitId: reimbursement.splitId,
      owedAmount: reimbursement.split.owedAmount,
      amount: reimbursement.amount,
      currentSettled: reimbursement.split.settledAmount,
    });
  },
};
