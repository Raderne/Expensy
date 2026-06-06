import { prisma } from '../lib/prisma.js';

export interface CreateCategoryInput {
  userId: string;
  key: string;
  label: string;
  abbr: string;
  color: string;
  bgTint: string;
  sort: number;
}

export type UpdateCategoryData = Partial<{
  label: string;
  abbr: string;
  color: string;
  bgTint: string;
}>;

export const categoryRepository = {
  findAll: (userId?: string) =>
    prisma.category.findMany({
      where: {
        OR: [
          { isSystem: true },
          ...(userId ? [{ userId }] : []),
        ],
      },
      orderBy: [{ isSystem: 'desc' }, { sort: 'asc' }, { createdAt: 'asc' }],
    }),

  findById: (id: string) =>
    prisma.category.findFirst({ where: { id } }),

  findByKey: (key: string, userId: string) =>
    prisma.category.findFirst({ where: { key, userId } }),

  create: (input: CreateCategoryInput) =>
    prisma.category.create({ data: { ...input, isSystem: false } }),

  update: (id: string, userId: string, data: UpdateCategoryData) =>
    prisma.category.updateMany({ where: { id, userId }, data }),

  softDelete: (id: string, userId: string) =>
    prisma.category.updateMany({
      where: { id, userId },
      data: { deletedAt: new Date() },
    }),
};
