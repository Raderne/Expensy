import { Router } from 'express';
import { authController } from '../controllers/authController.js';
import { budgetRolloverController } from '../controllers/budgetRolloverController.js';
import { contactController } from '../controllers/contactController.js';
import { dashboardController } from '../controllers/dashboardController.js';
import { sharedController } from '../controllers/sharedController.js';
import { transactionController } from '../controllers/transactionController.js';
import { userController } from '../controllers/userController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { idempotencyMiddleware } from '../middleware/idempotency.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const meRouter = Router();
meRouter.get('/me', requireAuth, asyncHandler(authController.me));
meRouter.put('/me', requireAuth, idempotencyMiddleware, asyncHandler(userController.updateProfile));
meRouter.patch(
  '/me/password',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(userController.changePassword),
);
meRouter.get('/me/summary', requireAuth, asyncHandler(dashboardController.summary));
meRouter.put(
  '/me/budget',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(dashboardController.upsertBudget),
);
meRouter.put(
  '/me/opening-balance',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(userController.updateOpeningBalance),
);
// Leftover budget from closed months that the user can move into savings goals.
meRouter.get(
  '/me/budget/rollovers',
  requireAuth,
  asyncHandler(budgetRolloverController.list),
);
meRouter.post(
  '/me/budget/rollovers/:month/allocate',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(budgetRolloverController.allocate),
);
meRouter.get(
  '/me/transaction-months',
  requireAuth,
  asyncHandler(transactionController.months),
);

// --- Contacts (people the user splits shared expenses with) ---
meRouter.get('/me/contacts', requireAuth, asyncHandler(contactController.list));
meRouter.post(
  '/me/contacts',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(contactController.create),
);
meRouter.put(
  '/me/contacts/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(contactController.update),
);
meRouter.delete(
  '/me/contacts/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(contactController.remove),
);

// --- Shared expenses: "who owes me" + settlement ---
meRouter.get('/me/shared/owed', requireAuth, asyncHandler(sharedController.owed));
meRouter.post(
  '/me/shared/splits/:id/reimbursements',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(sharedController.createReimbursement),
);
meRouter.delete(
  '/me/shared/reimbursements/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(sharedController.deleteReimbursement),
);
