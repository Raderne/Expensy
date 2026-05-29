import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';
import {
  PAGE_SIZE,
  transactionRepository,
  type ListFilters,
} from '../repositories/transactionRepository.js';
import { incomeService } from './incomeService.js';

const parseMonth = (month: string): { from: Date; to: Date } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  return { from: new Date(year, m - 1, 1), to: new Date(year, m, 1) };
};

const parseCursor = (cursor: string): { occurredAt: Date; id: string } => {
  const pipe = cursor.indexOf('|');
  const occurredAt = new Date(cursor.slice(0, pipe));
  const id = cursor.slice(pipe + 1);
  if (Number.isNaN(occurredAt.getTime())) {
    throw new AppError({ status: 400, code: 'INVALID_CURSOR', message: 'cursor is invalid' });
  }
  return { occurredAt, id };
};

export interface TransactionDto {
  id: string;
  amount: number;
  note: string | null;
  occurredAt: string;
  recurringIncomeId: string | null;
  category: { id: string; key: string; label: string; abbr: string; color: string; bgTint: string };
}

interface RawTx {
  id: string;
  amount: Prisma.Decimal;
  note: string | null;
  occurredAt: Date;
  recurringIncomeId: string | null;
  category: { id: string; key: string; label: string; abbr: string; color: string; bgTint: string };
}

const toDto = (t: RawTx): TransactionDto => ({
  id: t.id,
  amount: t.amount.toNumber(),
  note: t.note,
  occurredAt: t.occurredAt.toISOString(),
  recurringIncomeId: t.recurringIncomeId,
  category: {
    id: t.category.id,
    key: t.category.key,
    label: t.category.label,
    abbr: t.category.abbr,
    color: t.category.color,
    bgTint: t.category.bgTint,
  },
});

export const transactionService = {
  // Phase 04 — creates an expense. Client sends positive `amount`; we negate.
  async create(
    userId: string,
    input: { categoryId: string; amount: number; note?: string; occurredAt?: string },
  ): Promise<TransactionDto> {
    // Verify the category exists (and is not soft-deleted) — gives a clean 404
    // rather than a P2003 foreign-key error.
    const category = await prisma.category.findFirst({ where: { id: input.categoryId } });
    if (!category) {
      throw new AppError({
        status: 404,
        code: 'CATEGORY_NOT_FOUND',
        message: 'Category does not exist',
      });
    }

    const created = await transactionRepository.create({
      userId,
      categoryId: input.categoryId,
      amount: new Prisma.Decimal(-input.amount),
      note: input.note,
      occurredAt: input.occurredAt ? new Date(input.occurredAt) : new Date(),
    });

    return toDto(created);
  },

  // Phase 05 — paginated list, newest first.
  async list(
    userId: string,
    query: { month?: string; categoryId?: string; type?: 'income' | 'expense'; cursor?: string },
  ): Promise<{ transactions: TransactionDto[]; nextCursor: string | null }> {
    if (query.month) {
      await incomeService.ensureMaterialized(userId, query.month);
    }

    const filters: ListFilters = { userId };
    if (query.month) {
      const { from, to } = parseMonth(query.month);
      filters.from = from;
      filters.to = to;
    }
    if (query.categoryId) filters.categoryId = query.categoryId;
    if (query.type) filters.type = query.type;
    if (query.cursor) filters.cursor = parseCursor(query.cursor);

    const rows = await transactionRepository.list(filters);

    let nextCursor: string | null = null;
    let page = rows;
    if (rows.length > PAGE_SIZE) {
      page = rows.slice(0, PAGE_SIZE);
      const last = page[page.length - 1]!;
      nextCursor = `${last.occurredAt.toISOString()}|${last.id}`;
    }

    return { transactions: page.map(toDto), nextCursor };
  },

  // Phase 05 — months with at least one transaction, newest first.
  async listMonths(userId: string): Promise<string[]> {
    const rows = await transactionRepository.findMonths(userId);
    return rows.map((r) => r.month);
  },

  async delete(userId: string, id: string): Promise<void> {
    const tx = await transactionRepository.findById(id, userId);
    if (!tx) {
      throw new AppError({
        status: 404,
        code: 'TRANSACTION_NOT_FOUND',
        message: 'Transaction does not exist',
      });
    }
    if (tx.recurringIncomeId) {
      throw new AppError({
        status: 403,
        code: 'RECURRING_INCOME_PROTECTED',
        message: 'Recurring income transactions cannot be deleted here. Edit or pause the income source in Profile.',
      });
    }
    await transactionRepository.softDelete(id, userId);
  },
};
