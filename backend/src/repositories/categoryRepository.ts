import { prisma } from '../lib/prisma.js';

export const categoryRepository = {
  findAll: () => prisma.category.findMany({ orderBy: { sort: 'asc' } }),
};
