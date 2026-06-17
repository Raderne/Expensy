import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { totalOwedForShares } from '../lib/shares.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { contactRepository } from '../repositories/contactRepository.js';
import {
  recurringExpenseRepository,
  type ShareInput,
} from '../repositories/recurringExpenseRepository.js';
import { recurringOccurrenceRepository } from '../repositories/recurringOccurrenceRepository.js';
import type { PostponedOccurrenceDto } from './incomeService.js';
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

export interface RecurringShareDto {
  contactId: string;
  contactName: string;
  contactColor: string | null;
  shareType: 'AMOUNT' | 'PERCENT';
  shareValue: number;
}

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
  shares: RecurringShareDto[];
  postponed: PostponedOccurrenceDto | null;
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

const toDto = (
  row: RuleWithCategory,
  postponed: PostponedOccurrenceDto | null = null,
): RecurringExpenseDto => ({
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
  shares: row.shares.map((s) => ({
    contactId: s.contactId,
    contactName: s.contact.name,
    contactColor: s.contact.color,
    shareType: s.shareType as 'AMOUNT' | 'PERCENT',
    shareValue: s.shareValue.toNumber(),
  })),
  postponed,
});

// Validate that every share's contact belongs to the user and the resolved owed
// total stays below the bill amount (the user must keep a positive share).
// Returns the ShareInput[] ready for persistence.
const validateShares = async (
  userId: string,
  amount: Prisma.Decimal,
  shares: { contactId: string; shareType: 'AMOUNT' | 'PERCENT'; shareValue: number }[],
): Promise<ShareInput[]> => {
  if (shares.length === 0) return [];

  const contacts = await contactRepository.findByUser(userId);
  const validIds = new Set(contacts.map((c) => c.id));
  for (const s of shares) {
    if (!validIds.has(s.contactId)) {
      throw new AppError({
        status: 404,
        code: 'CONTACT_NOT_FOUND',
        message: `Contact ${s.contactId} not found`,
      });
    }
  }

  const shareInputs: ShareInput[] = shares.map((s) => ({
    contactId: s.contactId,
    shareType: s.shareType,
    shareValue: new Prisma.Decimal(s.shareValue),
  }));

  const owed = totalOwedForShares(shareInputs, amount);
  if (owed.greaterThanOrEqualTo(amount)) {
    throw new AppError({
      status: 400,
      code: 'SHARES_EXCEED_AMOUNT',
      message: 'split shares must total less than the recurring amount',
    });
  }

  return shareInputs;
};

// Map each recurring-expense rule id → its soonest active postpone (if any).
const loadPostponedExpense = async (
  userId: string,
): Promise<Map<string, PostponedOccurrenceDto>> => {
  const rows = await recurringOccurrenceRepository.findActivePostponed(userId);
  const byRule = new Map<string, PostponedOccurrenceDto>();
  for (const row of rows) {
    if (!row.recurringExpenseId) continue;
    // findActivePostponed is ordered by dueAt asc, so the first wins.
    if (byRule.has(row.recurringExpenseId)) continue;
    byRule.set(row.recurringExpenseId, {
      id: row.id,
      scheduledFor: row.scheduledFor.toISOString(),
      dueAt: row.dueAt.toISOString(),
    });
  }
  return byRule;
};

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
    const postponedByRule = await loadPostponedExpense(userId);
    return rows.map((row) => toDto(row, postponedByRule.get(row.id) ?? null));
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
      shares?: { contactId: string; shareType: 'AMOUNT' | 'PERCENT'; shareValue: number }[];
    },
  ): Promise<RecurringExpenseDto> {
    const categoryId = await resolveCategoryId(input.categoryId, userId);
    const amount = new Prisma.Decimal(input.amount);
    const shareInputs = await validateShares(userId, amount, input.shares ?? []);

    const created = await recurringExpenseRepository.create({
      userId,
      categoryId,
      label: input.label,
      amount,
      frequency: input.frequency,
      intervalDays: input.frequency === 'CUSTOM' ? (input.intervalDays ?? null) : null,
      anchorDate: startOfDay(new Date(input.anchorDate)),
    });
    if (shareInputs.length > 0) {
      await recurringExpenseRepository.replaceShares(created.id, userId, shareInputs);
    }
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
      shares?: { contactId: string; shareType: 'AMOUNT' | 'PERCENT'; shareValue: number }[];
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

    // Replace the split template when provided. Validate against the new amount
    // if it changed, otherwise the existing one.
    if (input.shares !== undefined) {
      const effectiveAmount =
        input.amount !== undefined ? new Prisma.Decimal(input.amount) : existing.amount;
      const shareInputs = await validateShares(userId, effectiveAmount, input.shares);
      await recurringExpenseRepository.replaceShares(id, userId, shareInputs);
    }

    // Keep still-actionable occurrences' snapshot in step with the edit.
    const snapshot: Partial<{ amount: Prisma.Decimal; label: string }> = {};
    if (input.amount !== undefined) snapshot.amount = new Prisma.Decimal(input.amount);
    if (input.label !== undefined) snapshot.label = input.label;
    if (Object.keys(snapshot).length > 0) {
      await recurringOccurrenceRepository.updateSnapshotForRule(
        { recurringExpenseId: id },
        userId,
        snapshot,
      );
    }

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
    await Promise.all([
      recurringExpenseRepository.softDelete(id, userId),
      recurringOccurrenceRepository.cancelForRule({ recurringExpenseId: id }, userId),
    ]);
  },

  // Generate a PENDING occurrence for every due charge up to `untilDate`. No
  // Transaction is created here — that happens only when the user confirms
  // (recurringOccurrenceService.confirm), so unconfirmed charges never affect
  // balances. Idempotent via the (rule, scheduledFor) unique index.
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

      // Stored positive; the sign is flipped when a Transaction is created.
      const amount = new Prisma.Decimal(rule.amount);

      for (const dueDate of dueDates) {
        await recurringOccurrenceRepository.upsertScheduled({
          userId,
          recurringExpenseId: rule.id,
          scheduledFor: startOfDay(dueDate),
          amount,
          label: rule.label,
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
