import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { recurringOccurrenceRepository } from '../repositories/recurringOccurrenceRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';
import { incomeService } from './incomeService.js';
import { recurringExpenseService } from './recurringExpenseService.js';

const startOfDay = (d: Date): Date => new Date(d.getFullYear(), d.getMonth(), d.getDate());

export interface PendingOccurrenceDto {
  id: string;
  type: 'income' | 'expense';
  label: string;
  amount: number;
  scheduledFor: string;
  dueAt: string;
  categoryKey: string;
  categoryColor: string;
}

export interface ConfirmedTransactionDto {
  id: string;
  amount: number;
  note: string | null;
  occurredAt: string;
  category: {
    id: string;
    key: string;
    label: string;
    abbr: string;
    color: string;
    bgTint: string;
    isSystem: boolean;
  };
}

type OccurrenceRow = NonNullable<
  Awaited<ReturnType<typeof recurringOccurrenceRepository.findById>>
>;

const getIncomeCategory = async () => {
  const categories = await categoryRepository.findAll();
  const income = categories.find((c) => c.key === 'income');
  if (!income) {
    throw new AppError({
      status: 500,
      code: 'INCOME_CATEGORY_MISSING',
      message: 'Income category is not configured',
    });
  }
  return income;
};

export const recurringOccurrenceService = {
  // Occurrences due now and awaiting confirm/postpone. Materializes first so
  // freshly-due paydays/charges show up without a separate trigger.
  async listDue(userId: string): Promise<PendingOccurrenceDto[]> {
    await incomeService.ensureMaterialized(userId);
    await recurringExpenseService.ensureMaterialized(userId);

    const today = startOfDay(new Date());
    const rows = await recurringOccurrenceRepository.findDue(userId, today);
    if (rows.length === 0) return [];

    // Income occurrences share the global income category for display.
    const needsIncomeCategory = rows.some((r) => r.recurringIncomeId);
    const incomeCategory = needsIncomeCategory ? await getIncomeCategory() : null;

    return rows.map((row) => {
      const isIncome = Boolean(row.recurringIncomeId);
      const category = isIncome ? incomeCategory! : row.recurringExpense!.category;
      return {
        id: row.id,
        type: isIncome ? 'income' : 'expense',
        label: row.label,
        amount: row.amount.toNumber(),
        scheduledFor: row.scheduledFor.toISOString(),
        dueAt: row.dueAt.toISOString(),
        categoryKey: category.key,
        categoryColor: category.color,
      };
    });
  },

  async confirm(userId: string, id: string): Promise<ConfirmedTransactionDto> {
    const occurrence = await recurringOccurrenceRepository.findById(id, userId);
    if (!occurrence) {
      throw new AppError({
        status: 404,
        code: 'OCCURRENCE_NOT_FOUND',
        message: 'Recurring occurrence not found',
      });
    }
    if (occurrence.status === 'CONFIRMED') {
      throw new AppError({
        status: 409,
        code: 'OCCURRENCE_ALREADY_CONFIRMED',
        message: 'This occurrence has already been confirmed',
      });
    }

    const isIncome = Boolean(occurrence.recurringIncomeId);
    const { categoryId, amount } = await resolveTransactionFields(occurrence, isIncome);

    const tx = await transactionRepository.create({
      userId,
      categoryId,
      amount,
      note: occurrence.label,
      occurredAt: startOfDay(occurrence.dueAt),
      recurringIncomeId: occurrence.recurringIncomeId ?? undefined,
      recurringExpenseId: occurrence.recurringExpenseId ?? undefined,
    });

    await recurringOccurrenceRepository.markConfirmed(id, userId, tx.id);

    return {
      id: tx.id,
      amount: tx.amount.toNumber(),
      note: tx.note,
      occurredAt: tx.occurredAt.toISOString(),
      category: {
        id: tx.category.id,
        key: tx.category.key,
        label: tx.category.label,
        abbr: tx.category.abbr,
        color: tx.category.color,
        bgTint: tx.category.bgTint,
        isSystem: tx.category.isSystem,
      },
    };
  },

  async postpone(userId: string, id: string, postponeTo: string): Promise<void> {
    const occurrence = await recurringOccurrenceRepository.findById(id, userId);
    if (!occurrence) {
      throw new AppError({
        status: 404,
        code: 'OCCURRENCE_NOT_FOUND',
        message: 'Recurring occurrence not found',
      });
    }
    if (occurrence.status === 'CONFIRMED') {
      throw new AppError({
        status: 409,
        code: 'OCCURRENCE_ALREADY_CONFIRMED',
        message: 'A confirmed occurrence cannot be postponed',
      });
    }

    const target = startOfDay(new Date(postponeTo));
    const today = startOfDay(new Date());
    if (target <= today) {
      throw new AppError({
        status: 400,
        code: 'POSTPONE_DATE_NOT_FUTURE',
        message: 'postponeTo must be a future date',
      });
    }

    await recurringOccurrenceRepository.postpone(id, userId, target);
  },
};

// Income → positive amount + income category. Expense → negated amount + the
// rule's own category.
const resolveTransactionFields = async (
  occurrence: OccurrenceRow,
  isIncome: boolean,
): Promise<{ categoryId: string; amount: Prisma.Decimal }> => {
  if (isIncome) {
    const income = await getIncomeCategory();
    return { categoryId: income.id, amount: new Prisma.Decimal(occurrence.amount) };
  }
  return {
    categoryId: occurrence.recurringExpense!.categoryId,
    amount: new Prisma.Decimal(occurrence.amount).negated(),
  };
};
