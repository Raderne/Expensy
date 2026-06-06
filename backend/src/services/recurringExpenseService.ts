import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { recurringExpenseRepository } from '../repositories/recurringExpenseRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';
import {
  occurrencesBetween,
  upcomingOccurrences,
  type RecurrenceFrequency,
} from '../lib/recurrence.js';

const startOfDay = (d: Date): Date =>
  new Date(d.getFullYear(), d.getMonth(), d.getDate());

const addDays = (d: Date, days: number): Date => {
  const next = new Date(d);
  next.setDate(next.getDate() + days);
  return next;
};

const SUBSCRIPTIONS_KEY = 'subscriptions';

export interface RecurringExpenseDto {
  id: string;
  label: string;
  amount: number;
  categoryId: string;
  categoryKey: string;
  categoryLabel: string;
  categoryColor: string;
  frequency: RecurrenceFrequency;
  intervalDays: number | null;
  anchorDate: string;
  isActive: boolean;
}

export interface UpcomingBillDto {
  ruleId: string;
  label: string;
  amount: number;
  occurredAt: string;
  categoryId: string;
  categoryKey: string;
  categoryColor: string;
}

type RuleWithCategory = Awaited<ReturnType<typeof recurringExpenseRepository.findByUser>>[number];

const toDto = (row: RuleWithCategory): RecurringExpenseDto => ({
  id: row.id,
  label: row.label,
  amount: row.amount.toNumber(),
  categoryId: row.categoryId,
  categoryKey: row.category.key,
  categoryLabel: row.category.label,
  categoryColor: row.category.color,
  frequency: row.frequency as RecurrenceFrequency,
  intervalDays: row.intervalDays,
  anchorDate: row.anchorDate.toISOString(),
  isActive: row.isActive,
});

const resolveCategoryId = async (categoryId: string | undefined, userId: string): Promise<string> => {
  const categories = await categoryRepository.findAll(userId);
  if (categoryId) {
    const match = categories.find((c) => c.id === categoryId);
    if (!match) {
      throw new AppError({
        status: 404,
        code: 'CATEGORY_NOT_FOUND',
        message: 'Category not found',
      });
    }
    return match.id;
  }
  const fallback = categories.find((c) => c.key === SUBSCRIPTIONS_KEY);
  if (!fallback) {
    throw new AppError({
      status: 500,
      code: 'SUBSCRIPTIONS_CATEGORY_MISSING',
      message: 'Subscriptions category is not configured',
    });
  }
  return fallback.id;
};

export const recurringExpenseService = {
  async list(userId: string): Promise<RecurringExpenseDto[]> {
    const rows = await recurringExpenseRepository.findByUser(userId);
    return rows.map(toDto);
  },

  async create(
    userId: string,
    input: {
      label: string;
      amount: number;
      categoryId?: string;
      frequency: RecurrenceFrequency;
      intervalDays?: number;
      anchorDate: string;
    },
  ): Promise<RecurringExpenseDto> {
    const categoryId = await resolveCategoryId(input.categoryId, userId);
    const created = await recurringExpenseRepository.create({
      userId,
      categoryId,
      label: input.label,
      amount: new Prisma.Decimal(input.amount),
      frequency: input.frequency,
      intervalDays: input.frequency === 'CUSTOM' ? (input.intervalDays ?? null) : null,
      anchorDate: startOfDay(new Date(input.anchorDate)),
    });
    await recurringExpenseService.ensureMaterialized(userId);
    const reloaded = await recurringExpenseRepository.findById(created.id, userId);
    return toDto(reloaded!);
  },

  async update(
    userId: string,
    id: string,
    input: {
      label?: string;
      amount?: number;
      categoryId?: string;
      frequency?: RecurrenceFrequency;
      intervalDays?: number | null;
      anchorDate?: string;
      isActive?: boolean;
    },
  ): Promise<RecurringExpenseDto> {
    const existing = await recurringExpenseRepository.findById(id, userId);
    if (!existing) {
      throw new AppError({
        status: 404,
        code: 'RECURRING_EXPENSE_NOT_FOUND',
        message: 'Recurring expense not found',
      });
    }

    const data: Parameters<typeof recurringExpenseRepository.update>[2] = {};
    if (input.label !== undefined) data.label = input.label;
    if (input.amount !== undefined) data.amount = new Prisma.Decimal(input.amount);
    if (input.categoryId !== undefined) {
      data.categoryId = await resolveCategoryId(input.categoryId, userId);
    }
    if (input.frequency !== undefined) data.frequency = input.frequency;
    if (input.intervalDays !== undefined) data.intervalDays = input.intervalDays;
    if (input.anchorDate !== undefined) data.anchorDate = startOfDay(new Date(input.anchorDate));
    if (input.isActive !== undefined) data.isActive = input.isActive;

    // Force consistency: non-CUSTOM frequencies must have null intervalDays.
    const newFrequency = input.frequency ?? (existing.frequency as RecurrenceFrequency);
    if (newFrequency !== 'CUSTOM') data.intervalDays = null;

    await recurringExpenseRepository.update(id, userId, data);
    await recurringExpenseService.ensureMaterialized(userId);

    const updated = await recurringExpenseRepository.findById(id, userId);
    return toDto(updated!);
  },

  async delete(userId: string, id: string): Promise<void> {
    const existing = await recurringExpenseRepository.findById(id, userId);
    if (!existing) {
      throw new AppError({
        status: 404,
        code: 'RECURRING_EXPENSE_NOT_FOUND',
        message: 'Recurring expense not found',
      });
    }
    await recurringExpenseRepository.softDelete(id, userId);
  },

  async ensureMaterialized(userId: string, untilDate: Date = new Date()): Promise<void> {
    const rules = await recurringExpenseRepository.findActiveByUser(userId);
    if (rules.length === 0) return;

    const today = startOfDay(untilDate);

    for (const rule of rules) {
      const anchor = startOfDay(rule.anchorDate);
      const ruleCreated = startOfDay(rule.createdAt);
      // Materialize from the later of the anchor and when the rule was created
      // (so historical anchors don't backfill 5 years of charges).
      const from = anchor > ruleCreated ? anchor : ruleCreated;
      if (from > today) continue;

      const dueDates = occurrencesBetween(
        {
          frequency: rule.frequency as RecurrenceFrequency,
          anchorDate: rule.anchorDate,
          intervalDays: rule.intervalDays,
        },
        from,
        today,
      );

      const amount = new Prisma.Decimal(rule.amount).negated();

      for (const dueDate of dueDates) {
        const dayStart = startOfDay(dueDate);
        const dayEnd = addDays(dayStart, 1);
        const existing = await transactionRepository.findByRecurringExpenseOnDay(
          rule.id,
          userId,
          dayStart,
          dayEnd,
        );
        if (existing) continue;

        await transactionRepository.create({
          userId,
          categoryId: rule.categoryId,
          amount,
          note: rule.label,
          occurredAt: dayStart,
          recurringExpenseId: rule.id,
        });
      }
    }
  },

  async listUpcoming(userId: string, limit: number): Promise<UpcomingBillDto[]> {
    const rules = await recurringExpenseRepository.findActiveByUser(userId);
    if (rules.length === 0) return [];

    const today = startOfDay(new Date());
    const tomorrow = addDays(today, 1);

    const out: UpcomingBillDto[] = [];
    for (const rule of rules) {
      const next = upcomingOccurrences(
        {
          frequency: rule.frequency as RecurrenceFrequency,
          anchorDate: rule.anchorDate,
          intervalDays: rule.intervalDays,
        },
        tomorrow,
        limit,
      );
      for (const dueDate of next) {
        out.push({
          ruleId: rule.id,
          label: rule.label,
          amount: rule.amount.toNumber(),
          occurredAt: dueDate.toISOString(),
          categoryId: rule.categoryId,
          categoryKey: rule.category.key,
          categoryColor: rule.category.color,
        });
      }
    }

    out.sort((a, b) => a.occurredAt.localeCompare(b.occurredAt));
    return out.slice(0, limit);
  },
};
