import { Router } from 'express';
import { recurringOccurrenceController } from '../controllers/recurringOccurrenceController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { idempotencyMiddleware } from '../middleware/idempotency.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const recurringOccurrencesRouter = Router();

recurringOccurrencesRouter.get(
  '/me/recurring/pending',
  requireAuth,
  asyncHandler(recurringOccurrenceController.listPending),
);
recurringOccurrencesRouter.get(
  '/me/recurring/postponed',
  requireAuth,
  asyncHandler(recurringOccurrenceController.listPostponed),
);
recurringOccurrencesRouter.post(
  '/me/recurring/occurrences/:id/confirm',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(recurringOccurrenceController.confirm),
);
recurringOccurrencesRouter.post(
  '/me/recurring/occurrences/:id/postpone',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(recurringOccurrenceController.postpone),
);
recurringOccurrencesRouter.post(
  '/me/recurring/occurrences/:id/reset',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(recurringOccurrenceController.reset),
);
