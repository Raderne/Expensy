import { schedule } from 'node-cron';
import { logger } from '../lib/logger.js';
import { runBudgetRollover } from './budgetRollover.js';

// Cron expression: 00:05 UTC on the 1st of every month.
const BUDGET_ROLLOVER_CRON = '5 0 1 * *';

/**
 * Registers scheduled jobs. Started from the server entrypoint (index.ts) only,
 * so tests (which build the app via app.ts) never spin up a scheduler.
 *
 * Assumes a single always-on instance (Render). If the app is ever scaled
 * horizontally this needs a distributed lock to avoid duplicate rollovers.
 */
export function startScheduler(): void {
  schedule(
    BUDGET_ROLLOVER_CRON,
    () => {
      runBudgetRollover().catch((err) =>
        logger.error({ err }, 'budget rollover job crashed'),
      );
    },
    { timezone: 'UTC', name: 'budget-rollover' },
  );
  logger.info({ cron: BUDGET_ROLLOVER_CRON }, 'scheduler started: budget rollover');
}
