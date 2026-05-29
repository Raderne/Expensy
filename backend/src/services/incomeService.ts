import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { recurringIncomeRepository } from '../repositories/recurringIncomeRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';

const parseMonth = (month: string): { from: Date; to: Date; year: number; m: number } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  return { from: new Date(year, m - 1, 1), to: new Date(year, m, 1), year, m };
};

const currentMonth = (): string => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
};

const paydayInMonth = (year: number, month: number, dayOfMonth: number): Date =>
  new Date(year, month - 1, dayOfMonth);

const startOfDay = (d: Date): Date => new Date(d.getFullYear(), d.getMonth(), d.getDate());

export interface RecurringIncomeDto {
  id: string;
  label: string;
  amount: number;
  dayOfMonth: number;
  isActive: boolean;
}

export interface SideIncomeDto {
  id: string;
  amount: number;
  note: string | null;
  occurredAt: string;
}

const toRecurringDto = (row: {
  id: string;
  label: string;
  amount: Prisma.Decimal;
  dayOfMonth: number;
  isActive: boolean;
}): RecurringIncomeDto => ({
  id: row.id,
  label: row.label,
  amount: row.amount.toNumber(),
  dayOfMonth: row.dayOfMonth,
  isActive: row.isActive,
});

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
    return rows.map(toRecurringDto);
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
    await incomeService.ensureMaterialized(userId, currentMonth());
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

    const month = currentMonth();
    await incomeService.ensureMaterialized(userId, month);

    const label = input.label ?? existing.label;
    const amount = input.amount ?? existing.amount.toNumber();
    const dayOfMonth = input.dayOfMonth ?? existing.dayOfMonth;
    const { year, m } = parseMonth(month);
    const payday = paydayInMonth(year, m, dayOfMonth);

    const linked = await transactionRepository.findByRecurringInMonth(id, userId, month);
    if (linked) {
      await transactionRepository.update(linked.id, userId, {
        amount: new Prisma.Decimal(amount),
        note: label,
        occurredAt: payday,
      });
    }

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

  async ensureMaterialized(userId: string, month: string): Promise<void> {
    const { year, m } = parseMonth(month);
    const today = startOfDay(new Date());
    const sources = await recurringIncomeRepository.findByUser(userId);
    const active = sources.filter((s) => s.isActive);
    if (active.length === 0) return;

    const categoryId = await getIncomeCategoryId();

    for (const source of active) {
      const sourceCreatedMonth = `${source.createdAt.getFullYear()}-${String(source.createdAt.getMonth() + 1).padStart(2, '0')}`;
      if (month < sourceCreatedMonth) continue;

      const payday = paydayInMonth(year, m, source.dayOfMonth);
      if (startOfDay(payday) > today) continue;

      const existing = await transactionRepository.findByRecurringInMonth(source.id, userId, month);
      if (existing) continue;

      await transactionRepository.create({
        userId,
        categoryId,
        amount: source.amount,
        note: source.label,
        occurredAt: payday,
        recurringIncomeId: source.id,
      });
    }
  },
};
