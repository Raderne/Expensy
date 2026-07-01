import { logger } from '../lib/logger.js';
import { runBudgetRollover } from './budgetRollover.js';

// Manual/safety trigger for the month-end budget rollover: `npm run job:rollover`.
// Pass a 'YYYY-MM-01'-ish date as the first arg to roll a specific month over
// (the job closes the month *before* the given date's month).
const arg = process.argv[2];
const now = arg ? new Date(arg) : new Date();

runBudgetRollover(now)
  .then(() => {
    logger.info('manual budget rollover finished');
    process.exit(0);
  })
  .catch((err) => {
    logger.error({ err }, 'manual budget rollover failed');
    process.exit(1);
  });
