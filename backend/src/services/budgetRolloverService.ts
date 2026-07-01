import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';
import { goalRepository } from '../repositories/goalRepository.js';
import { monthlyBudgetRepository } from '../repositories/monthlyBudgetRepository.js';
import type { AllocateBody } from '../schemas/budgetRollover.js';

export interface RolloverDto {
  month: string;
  amount: number;
  spent: number;
  remaining: number;
}

const toDto = (r: {
  month: string;
  amount: Prisma.Decimal;
  spent: Prisma.Decimal;
  allocated: Prisma.Decimal;
}): RolloverDto => ({
  month: r.month,
  amount: r.amount.toNumber(),
  spent: r.spent.toNumber(),
  remaining: r.amount.minus(r.spent).minus(r.allocated).toNumber(),
});

export const budgetRolloverService = {
  // Closed months with an unconsumed, unallocated remainder the user can still
  // move into savings goals.
  async listAllocatable(userId: string): Promise<RolloverDto[]> {
    const rows = await monthlyBudgetRepository.listAllocatable(userId);
    return rows.map(toDto);
  },

  // Moves `amount` of a closed month's leftover into a goal. Validates the goal
  // belongs to the user and the amount doesn't exceed the remaining leftover,
  // then bumps the goal and the month's `allocated` atomically.
  async allocate(
    userId: string,
    month: string,
    input: AllocateBody,
  ): Promise<RolloverDto> {
    const row = await monthlyBudgetRepository.findByUserMonth(userId, month);
    if (!row || !row.closed) {
      throw new AppError({
        status: 404,
        code: 'ROLLOVER_NOT_FOUND',
        message: 'No closed budget for that month',
      });
    }

    const remaining = row.amount.minus(row.spent).minus(row.allocated);
    const amount = new Prisma.Decimal(input.amount);
    if (amount.greaterThan(remaining)) {
      throw new AppError({
        status: 400,
        code: 'ALLOCATION_EXCEEDS_REMAINING',
        message: 'Amount exceeds the remaining budget for that month',
      });
    }

    const goal = await goalRepository.findById(input.goalId, userId);
    if (!goal) {
      throw new AppError({
        status: 404,
        code: 'GOAL_NOT_FOUND',
        message: 'Goal not found',
      });
    }

    await prisma.$transaction([
      goalRepository.addFunds(input.goalId, userId, amount),
      monthlyBudgetRepository.incrementAllocated(userId, month, amount),
    ]);

    return {
      month: row.month,
      amount: row.amount.toNumber(),
      spent: row.spent.toNumber(),
      remaining: remaining.minus(amount).toNumber(),
    };
  },
};
