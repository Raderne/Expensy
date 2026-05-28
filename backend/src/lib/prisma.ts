import { Prisma, PrismaClient } from '@prisma/client';
import { env } from '../config/env.js';
import { requestContext } from './requestContext.js';

const base = new PrismaClient({
  log: env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
});

// =============================================================================
// Extension 1 — Audit stamps
//
// Stamps createdById / updatedById from the per-request AsyncLocalStorage actor
// on every write. Caller-supplied values always win (spread order puts them
// last). No-op when there is no actor (system tasks, signup, etc.).
//
// Covered: create, createMany, update, updateMany, upsert.
// =============================================================================
const auditExtension = Prisma.defineExtension({
  name: 'audit-stamps',
  query: {
    $allModels: {
      async create({ args, query }) {
        const actorId = requestContext.getActorId();
        if (actorId) {
          args.data = { createdById: actorId, updatedById: actorId, ...args.data };
        }
        return query(args);
      },
      async createMany({ args, query }) {
        const actorId = requestContext.getActorId();
        if (actorId && args.data) {
          const stamp = { createdById: actorId, updatedById: actorId };
          args.data = (
            Array.isArray(args.data)
              ? args.data.map((d) => ({ ...stamp, ...d }))
              : { ...stamp, ...args.data }
          ) as typeof args.data;
        }
        return query(args);
      },
      async update({ args, query }) {
        const actorId = requestContext.getActorId();
        if (actorId) {
          args.data = { updatedById: actorId, ...args.data };
        }
        return query(args);
      },
      async updateMany({ args, query }) {
        const actorId = requestContext.getActorId();
        if (actorId) {
          args.data = { updatedById: actorId, ...args.data };
        }
        return query(args);
      },
      async upsert({ args, query }) {
        const actorId = requestContext.getActorId();
        if (actorId) {
          args.create = { createdById: actorId, updatedById: actorId, ...args.create };
          args.update = { updatedById: actorId, ...args.update };
        }
        return query(args);
      },
    },
  },
});

// =============================================================================
// Extension 2 — Soft-delete filter
//
// Automatically prepends `deletedAt: null` to every read and bulk-mutation
// `where` so repositories never need to add it manually.
//
// Caller-supplied `deletedAt` always wins (spread puts caller last), so a
// specific query can still see deleted records when needed:
//   prisma.user.findFirst({ where: { id, deletedAt: { not: null } } })
//
// Covered reads:   findFirst, findFirstOrThrow, findMany, count, aggregate, groupBy
// Covered writes:  updateMany, deleteMany (bulk ops should not touch deleted rows)
//
// NOT intercepted: findUnique / findUniqueOrThrow
//   Prisma's `where` for findUnique only accepts fields covered by a unique
//   index. Adding `deletedAt` (not unique) causes a runtime error. Use
//   findFirst / findFirstOrThrow instead — which is already this project's
//   convention (see src/repositories/).
//
// NOT intercepted: update, delete, upsert (single-record by primary key)
//   The service layer verifies existence (and softness) before mutating.
// =============================================================================
const softDeleteExtension = Prisma.defineExtension({
  name: 'soft-delete-filter',
  query: {
    $allModels: {
      async findFirst({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
      async findFirstOrThrow({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
      async findMany({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
      async count({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
      async aggregate({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
      async groupBy({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
      async updateMany({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
      async deleteMany({ args, query }) {
        args.where = { deletedAt: null, ...args.where } as typeof args.where;
        return query(args);
      },
    },
  },
});

// Chain: softDeleteExtension wraps auditExtension.
// For reads:    softDelete filter fires first, audit is a no-op.
// For updateMany/deleteMany: softDelete adds `deletedAt: null` to where;
//                            audit adds `updatedById` to data. No conflict.
export const prisma = base.$extends(auditExtension).$extends(softDeleteExtension);

export type PrismaClientExtended = typeof prisma;
