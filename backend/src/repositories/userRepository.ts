import { prisma } from '../lib/prisma.js';

export const userRepository = {
  findByEmail: (email: string) =>
    prisma.user.findFirst({ where: { email } }),

  findById: (id: string) =>
    prisma.user.findFirst({ where: { id } }),

  create: (data: { email: string; passwordHash: string; name: string }) =>
    prisma.user.create({ data }),

  updateName: (id: string, name: string) =>
    prisma.user.update({ where: { id }, data: { name } }),

  updatePasswordHash: (id: string, passwordHash: string) =>
    prisma.user.update({ where: { id }, data: { passwordHash } }),
};

export type UserRepository = typeof userRepository;
