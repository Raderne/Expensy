import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { recurringIncomeRepository } from '../repositories/recurringIncomeRepository.js';
import { recurringOccurrenceRepository } from '../repositories/recurringOccurrenceRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';

const paydayInMonth = (year: number, month: number, dayOfMonth: number): Date =>
  new Date(year, month - 1, dayOfMonth);

const startOfDay = (d: Date): Date => new Date(d.getFullYear(), d.getMonth(), d.getDate());

const startOfMonth = (d: Date): Date => new Date(d.getFullYear(), d.getMonth(), 1);

export interface PostponedOccurrenceDto {
  id: string;
  scheduledFor: string;
  dueAt: string;
}

export interface RecurringIncomeDto {
  id: string;
  label: string;
  amount: number;
  dayOfMonth: number;
  isActive: boolean;
  postponed: PostponedOccurrenceDto | null;
}

export interface SideIncomeDto {
  id: string;
  amount: number;
  note: string | null;
  occurredAt: string;
}

const toRecurringDto = (
  row: {
    id: string;
    label: string;
    amount: Prisma.Decimal;
    dayOfMonth: number;
    isActive: boolean;
  },
  postponed: PostponedOccurrenceDto | null = null,
): RecurringIncomeDto => ({
  id: row.id,
  label: row.label,
  amount: row.amount.toNumber(),
  dayOfMonth: row.dayOfMonth,
  isActive: row.isActive,
  postponed,
});

// Map each recurring-income rule id → its soonest active postpone (if any).
const loadPostponedIncome = async (
  userId: string,
): Promise<Map<string, PostponedOccurrenceDto>> => {
  const rows = await recurringOccurrenceRepository.findActivePostponed(userId);
  const byRule = new Map<string, PostponedOccurrenceDto>();
  for (const row of rows) {
    if (!row.recurringIncomeId) continue;
    // findActivePostponed is ordered by dueAt asc, so the first wins.
    if (byRule.has(row.recurringIncomeId)) continue;
    byRule.set(row.recurringIncomeId, {
      id: row.id,
      scheduledFor: row.scheduledFor.toISOString(),
      dueAt: row.dueAt.toISOString(),
    });
  }
  return byRule;
};

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

export const incomeService = {
  async listRecurring(userId: string): Promise<RecurringIncomeDto[]> {
    const rows = await recurringIncomeRepository.findByUser(userId);
    const postponedByRule = await loadPostponedIncome(userId);
    return rows.map((row) => toRecurringDto(row, postponedByRule.get(row.id) ?? null));
  },

  async createRecurring(
    userId: string,
    input: { label: string; amount: number; dayOfMonth: number },
  ): Promise<RecurringIncomeDto> {
    const row = await recurringIncomeRepository.create({
      userId,
      label: input.label,
      amount: new Prisma.Decimal(input.amount),
      dayOfMonth: input.dayOfMonth,
    });
    await incomeService.ensureMaterialized(userId);
    return toRecurringDto(row);
  },

  async updateRecurring(
    userId: string,
    id: string,
    input: Partial<{ label: string; amount: number; dayOfMonth: number; isActive: boolean }>,
  ): Promise<RecurringIncomeDto> {
    const existing = await recurringIncomeRepository.findById(id, userId);
    if (!existing) {
      throw new AppError({
        status: 404,
        code: 'RECURRING_INCOME_NOT_FOUND',
        message: 'Recurring income source not found',
      });
    }

    const data: Partial<{
      label: string;
      amount: Prisma.Decimal;
      dayOfMonth: number;
      isActive: boolean;
    }> = {};
    if (input.label !== undefined) data.label = input.label;
    if (input.amount !== undefined) data.amount = new Prisma.Decimal(input.amount);
    if (input.dayOfMonth !== undefined) data.dayOfMonth = input.dayOfMonth;
    if (input.isActive !== undefined) data.isActive = input.isActive;

    await recurringIncomeRepository.update(id, userId, data);

    // Keep still-actionable occurrences' snapshot in step with the edit; already
    // confirmed paydays keep their original transaction.
    const snapshot: Partial<{ amount: Prisma.Decimal; label: string }> = {};
    if (input.amount !== undefined) snapshot.amount = new Prisma.Decimal(input.amount);
    if (input.label !== undefined) snapshot.label = input.label;
    if (Object.keys(snapshot).length > 0) {
      await recurringOccurrenceRepository.updateSnapshotForRule(
        { recurringIncomeId: id },
        userId,
        snapshot,
      );
    }

    await incomeService.ensureMaterialized(userId);

    const updated = await recurringIncomeRepository.findById(id, userId);
    return toRecurringDto(updated!);
  },

  async deleteRecurring(userId: string, id: string): Promise<void> {
    const existing = await recurringIncomeRepository.findById(id, userId);
    if (!existing) {
      throw new AppError({
        status: 404,
        code: 'RECURRING_INCOME_NOT_FOUND',
        message: 'Recurring income source not found',
      });
    }
    await recurringIncomeRepository.softDelete(id, userId);
  },

  async createSideIncome(
    userId: string,
    input: { amount: number; note?: string; occurredAt?: string },
  ): Promise<SideIncomeDto> {
    const categoryId = await getIncomeCategoryId();
    const created = await transactionRepository.create({
      userId,
      categoryId,
      amount: new Prisma.Decimal(input.amount),
      note: input.note,
      occurredAt: input.occurredAt ? new Date(input.occurredAt) : new Date(),
    });
    return {
      id: created.id,
      amount: created.amount.toNumber(),
      note: created.note,
      occurredAt: created.occurredAt.toISOString(),
    };
  },

  // Generate a PENDING occurrence for every payday from each source's creation
  // month up to the current month (paydays still in the future are skipped). No
  // Transaction is created here — confirmation does that — so unconfirmed income
  // never affects balances. Idempotent via the (rule, scheduledFor) unique index.
  async ensureMaterialized(userId: string): Promise<void> {
    const today = startOfDay(new Date());
    const sources = await recurringIncomeRepository.findByUser(userId);
    const active = sources.filter((s) => s.isActive);
    if (active.length === 0) return;

    const endMonth = startOfMonth(today);

    for (const source of active) {
      const createdStart = startOfDay(source.createdAt);
      let cursor = startOfMonth(source.createdAt);

      while (cursor <= endMonth) {
        const payday = startOfDay(
          paydayInMonth(cursor.getFullYear(), cursor.getMonth() + 1, source.dayOfMonth),
        );
        // Only generate paydays that have arrived and that fall on/after the
        // source's creation day (so a mid-month signup doesn't backfill an
        // earlier payday in the same month).
        if (payday <= today && payday >= createdStart) {
          await recurringOccurrenceRepository.upsertScheduled({
            userId,
            recurringIncomeId: source.id,
            scheduledFor: payday,
            amount: new Prisma.Decimal(source.amount),
            label: source.label,
          });
        }
        cursor = new Date(cursor.getFullYear(), cursor.getMonth() + 1, 1);
      }
    }
  },
};
