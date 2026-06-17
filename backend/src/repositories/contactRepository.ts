import { prisma } from '../lib/prisma.js';

export interface CreateContactInput {
  userId: string;
  name: string;
  color?: string | null;
}

export type UpdateContactData = Partial<{
  name: string;
  color: string | null;
}>;

export const contactRepository = {
  findByUser: (userId: string) =>
    prisma.contact.findMany({
      where: { userId },
      orderBy: [{ name: 'asc' }, { createdAt: 'asc' }],
    }),

  findById: (id: string, userId: string) =>
    prisma.contact.findFirst({ where: { id, userId } }),

  create: (input: CreateContactInput) =>
    prisma.contact.create({ data: input }),

  update: (id: string, userId: string, data: UpdateContactData) =>
    prisma.contact.updateMany({ where: { id, userId }, data }),

  softDelete: (id: string, userId: string) =>
    prisma.contact.updateMany({
      where: { id, userId },
      data: { deletedAt: new Date() },
    }),
};
