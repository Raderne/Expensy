import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { goalRepository } from '../repositories/goalRepository.js';
import type {
  CreateGoalBody,
  UpdateGoalBody,
  AddFundsBody,
} from '../schemas/goals.js';

export interface GoalDto {
  id: string;
  name: string;
  icon: string;
  color: string;
  targetAmount: number;
  savedAmount: number;
  targetDate: string | null;
}

const toDto = (row: {
  id: string;
  name: string;
  icon: string;
  color: string;
  targetAmount: Prisma.Decimal;
  savedAmount: Prisma.Decimal;
  targetDate: Date | null;
}): GoalDto => ({
  id: row.id,
  name: row.name,
  icon: row.icon,
  color: row.color,
  targetAmount: row.targetAmount.toNumber(),
  savedAmount: row.savedAmount.toNumber(),
  targetDate: row.targetDate ? row.targetDate.toISOString() : null,
});

const notFound = (): never => {
  throw new AppError({
    status: 404,
    code: 'GOAL_NOT_FOUND',
    message: 'Goal not found',
  });
};

export const goalService = {
  async list(userId: string): Promise<GoalDto[]> {
    const rows = await goalRepository.findByUser(userId);
    return rows.map(toDto);
  },

  async create(userId: string, input: CreateGoalBody): Promise<GoalDto> {
    const row = await goalRepository.create({
      userId,
      name: input.name,
      icon: input.icon,
      color: input.color,
      targetAmount: new Prisma.Decimal(input.targetAmount),
      savedAmount: new Prisma.Decimal(input.savedAmount ?? 0),
      targetDate: input.targetDate ? new Date(input.targetDate) : null,
    });
    return toDto(row);
  },

  async update(
    userId: string,
    id: string,
    input: UpdateGoalBody,
  ): Promise<GoalDto> {
    const existing = await goalRepository.findById(id, userId);
    if (!existing) notFound();

    const data: Partial<{
      name: string;
      icon: string;
      color: string;
      targetAmount: Prisma.Decimal;
      savedAmount: Prisma.Decimal;
      targetDate: Date | null;
    }> = {};
    if (input.name !== undefined) data.name = input.name;
    if (input.icon !== undefined) data.icon = input.icon;
    if (input.color !== undefined) data.color = input.color;
    if (input.targetAmount !== undefined) {
      data.targetAmount = new Prisma.Decimal(input.targetAmount);
    }
    if (input.savedAmount !== undefined) {
      data.savedAmount = new Prisma.Decimal(input.savedAmount);
    }
    // `targetDate` present (even as null) means set/clear it; absent means leave.
    if ('targetDate' in input) {
      data.targetDate = input.targetDate ? new Date(input.targetDate) : null;
    }

    await goalRepository.update(id, userId, data);
    const updated = await goalRepository.findById(id, userId);
    return toDto(updated!);
  },

  async addFunds(
    userId: string,
    id: string,
    input: AddFundsBody,
  ): Promise<GoalDto> {
    const existing = await goalRepository.findById(id, userId);
    if (!existing) notFound();
    await goalRepository.addFunds(id, userId, new Prisma.Decimal(input.amount));
    const updated = await goalRepository.findById(id, userId);
    return toDto(updated!);
  },

  async delete(userId: string, id: string): Promise<void> {
    const existing = await goalRepository.findById(id, userId);
    if (!existing) notFound();
    await goalRepository.softDelete(id, userId);
  },
};
