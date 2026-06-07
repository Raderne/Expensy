import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';

export interface UpsertOccurrenceInput {
  userId: string;
  recurringIncomeId?: string;
  recurringExpenseId?: string;
  scheduledFor: Date;
  amount: Prisma.Decimal;
  label: string;
}

// Occurrences awaiting user action: not yet confirmed and due on/before `before`.
const PENDING_STATUSES = ['PENDING', 'POSTPONED'] as const;

export const recurringOccurrenceRepository = {
  // Create a PENDING occurrence for (rule, scheduledFor) if one doesn't exist.
  // Idempotent via the (recurring*Id, scheduledFor) unique index, so repeated
  // materialization runs are safe. Returns void — callers don't need the row.
  upsertScheduled: async (input: UpsertOccurrenceInput): Promise<void> => {
    const where = input.recurringIncomeId
      ? {
          recurringIncomeId_scheduledFor: {
            recurringIncomeId: input.recurringIncomeId,
            scheduledFor: input.scheduledFor,
          },
        }
      : {
          recurringExpenseId_scheduledFor: {
            recurringExpenseId: input.recurringExpenseId!,
            scheduledFor: input.scheduledFor,
          },
        };

    await prisma.recurringOccurrence.upsert({
      where,
      create: {
        userId: input.userId,
        recurringIncomeId: input.recurringIncomeId,
        recurringExpenseId: input.recurringExpenseId,
        scheduledFor: input.scheduledFor,
        dueAt: input.scheduledFor,
        amount: input.amount,
        label: input.label,
      },
      // No-op on conflict: never resurrect a confirmed/postponed occurrence and
      // never overwrite a user's postpone choice. Snapshot edits go through
      // updateSnapshotForRule instead.
      update: {},
    });
  },

  findById: (id: string, userId: string) =>
    prisma.recurringOccurrence.findFirst({
      where: { id, userId },
      include: {
        recurringExpense: { include: { category: true } },
        recurringIncome: true,
      },
    }),

  // All occurrences the user has actively postponed (status POSTPONED),
  // soonest re-prompt first. Used to surface "this cycle is postponed to …" on
  // the rule in edit mode.
  findActivePostponed: (userId: string) =>
    prisma.recurringOccurrence.findMany({
      where: { userId, status: 'POSTPONED' },
      orderBy: [{ dueAt: 'asc' }],
    }),

  // Postponed occurrences with their rule/category, soonest re-prompt first.
  // Powers the "Postponed" management surface (confirm early or reschedule).
  findPostponed: (userId: string) =>
    prisma.recurringOccurrence.findMany({
      where: { userId, status: 'POSTPONED' },
      orderBy: [{ dueAt: 'asc' }],
      include: {
        recurringExpense: { include: { category: true } },
        recurringIncome: true,
      },
    }),

  // Occurrences the app should prompt for now: pending/postponed and due today
  // or earlier, oldest schedule first.
  findDue: (userId: string, before: Date) =>
    prisma.recurringOccurrence.findMany({
      where: {
        userId,
        status: { in: [...PENDING_STATUSES] },
        dueAt: { lte: before },
      },
      orderBy: [{ scheduledFor: 'asc' }],
      include: {
        recurringExpense: { include: { category: true } },
        recurringIncome: true,
      },
    }),

  markConfirmed: (id: string, userId: string, transactionId: string) =>
    prisma.recurringOccurrence.updateMany({
      where: { id, userId },
      data: { status: 'CONFIRMED', transactionId },
    }),

  postpone: (id: string, userId: string, dueAt: Date) =>
    prisma.recurringOccurrence.updateMany({
      where: { id, userId },
      data: { status: 'POSTPONED', dueAt },
    }),

  // Undo a postpone: re-prompt on the original scheduled day. Caller supplies
  // scheduledFor (read via findById) since Prisma can't reference another column.
  resetToScheduled: (id: string, userId: string, scheduledFor: Date) =>
    prisma.recurringOccurrence.updateMany({
      where: { id, userId },
      data: { status: 'PENDING', dueAt: scheduledFor },
    }),

  // Keep the snapshot of still-actionable occurrences in step with rule edits
  // (confirmed ones already have a transaction and are left untouched).
  updateSnapshotForRule: (
    rule: { recurringIncomeId?: string; recurringExpenseId?: string },
    userId: string,
    data: Partial<{ amount: Prisma.Decimal; label: string }>,
  ) =>
    prisma.recurringOccurrence.updateMany({
      where: {
        userId,
        status: { in: [...PENDING_STATUSES] },
        recurringIncomeId: rule.recurringIncomeId,
        recurringExpenseId: rule.recurringExpenseId,
      },
      data,
    }),
};
