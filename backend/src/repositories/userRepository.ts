import { prisma } from '../lib/prisma.js';

export const userRepository = {
  findByEmail: (email: string) =>
    prisma.user.findFirst({ where: { email } }),

  findById: (id: string) =>
    prisma.user.findFirst({ where: { id } }),

  create: (data: { email: string; passwordHash: string; name: string }) =>
    prisma.user.create({ data }),
};

export type UserRepository = typeof userRepository;
