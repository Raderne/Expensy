import { describe, expect, it } from 'vitest';
import {
  buildFinancialSnapshot,
  contiguousMonthsEnding,
  fallbackNarrative,
  resolveNarrative,
  safeLabel,
  snapshotFingerprint,
  toAnalysisPacket,
  type SnapshotBuildInput,
} from '../src/services/financialSnapshot.js';

const base = (overrides: Partial<SnapshotBuildInput> = {}): SnapshotBuildInput => ({
  month: '2026-06',
  months: [
    { month: '2026-01', income: 0, expenses: 0, budgetAmount: null },
    { month: '2026-02', income: 3000, expenses: 1800, budgetAmount: 2500 },
    { month: '2026-03', income: 3000, expenses: 2100, budgetAmount: 2500 },
    { month: '2026-04', income: 3000, expenses: 1900, budgetAmount: 2500 },
    { month: '2026-05', income: 2800, expenses: 2000, budgetAmount: 2500 },
    { month: '2026-06', income: 3000, expenses: 2600, budgetAmount: 2400 },
  ],
  categoriesByMonth: {
    '2026-02': [{ categoryId: 'food', label: 'Food', amount: 400 }],
    '2026-03': [{ categoryId: 'food', label: 'Food', amount: 500 }],
    '2026-04': [{ categoryId: 'food', label: 'Food', amount: 450 }],
    '2026-05': [{ categoryId: 'food', label: 'Food', amount: 450 }],
    '2026-06': [
      { categoryId: 'food', label: 'Food', amount: 1500 },
      { categoryId: 'fun', label: 'Fun', amount: 400 },
    ],
  },
  recurringExpenses: [{ label: 'Rent', monthlyAmount: 1200 }],
  recurringIncome: [{ label: 'Salary', monthlyAmount: 3000 }],
  upcoming: [],
  goals: [
    {
      name: 'Trip',
      savedAmount: 200,
      targetAmount: 1000,
      targetDate: '2026-12-01T00:00:00.000Z',
    },
  ],
  ...overrides,
});

describe('financial snapshot', () => {
  it('uses six contiguous months ending on the focal month, across a year boundary', () => {
    expect(contiguousMonthsEnding('2026-06', 6)).toEqual([
      '2026-01',
      '2026-02',
      '2026-03',
      '2026-04',
      '2026-05',
      '2026-06',
    ]);
    expect(contiguousMonthsEnding('2026-01', 6)).toEqual([
      '2025-08',
      '2025-09',
      '2025-10',
      '2025-11',
      '2025-12',
      '2026-01',
    ]);
  });

  it('computes savings, budget, month-over-month change, and category baseline', () => {
    const snapshot = buildFinancialSnapshot(base());
    expect(snapshot.scorecard).toMatchObject({
      income: 3000,
      expenses: 2600,
      net: 400,
      savingsRatePct: 13,
      budgetAmount: 2400,
      budgetPct: 108,
      expenseChangePct: 30,
    });
    expect(snapshot.trend).toHaveLength(6);
    expect(snapshot.trend[0]?.month).toBe('2026-01');
    expect(snapshot.trend[0]?.hasActivity).toBe(false);
    expect(snapshot.dataCoverage.historyMonths).toBe(5);

    const food = snapshot.categoryChanges.find((c) => c.categoryId === 'food');
    // Jan has no expenses, so it is not in the baseline. Average of 400/500/450/450.
    expect(food?.baselineAmount).toBe(450);
    expect(food?.changePct).toBe(Math.round(((1500 - 450) / 450) * 100));
    expect(food?.sharePct).toBe(Math.round((1500 / 2600) * 100));
    expect(snapshot.actions.map((a) => a.id)).toEqual([
      'review_budget',
      'review_category',
      'fund_goals',
    ]);
    expect(snapshot.actions.find((a) => a.id === 'set_budget')).toBeUndefined();
  });

  it('leaves savings rate empty when the month has spending and no income', () => {
    const snapshot = buildFinancialSnapshot(
      base({
        months: [
          { month: '2026-05', income: 0, expenses: 0, budgetAmount: null },
          { month: '2026-06', income: 0, expenses: 400, budgetAmount: null },
        ],
        categoriesByMonth: {
          '2026-06': [{ categoryId: 'food', label: 'Food', amount: 400 }],
        },
        recurringExpenses: [],
        recurringIncome: [],
        goals: [],
      }),
    );
    expect(snapshot.scorecard.savingsRatePct).toBeNull();
    expect(snapshot.scorecard.expenseChangePct).toBeNull();
    expect(snapshot.dataCoverage.limitations.join(' ')).toContain('Savings rate needs income');
    expect(fallbackNarrative(snapshot).headline).toContain('no recorded income');
  });

  it('offers a budget action only when no cap is set', () => {
    const snapshot = buildFinancialSnapshot(
      base({
        months: [{ month: '2026-06', income: 3000, expenses: 1000, budgetAmount: null }],
        categoriesByMonth: {
          '2026-06': [{ categoryId: 'food', label: 'Food', amount: 200 }],
        },
      }),
    );
    expect(snapshot.actions.some((a) => a.id === 'set_budget')).toBe(true);
    expect(snapshot.actions.some((a) => a.id === 'review_budget')).toBe(false);
  });

  it('changes the cache fingerprint when a figure changes and keeps the packet free of raw records', () => {
    const first = buildFinancialSnapshot(base());
    const second = buildFinancialSnapshot(
      base({
        months: base().months.map((m) =>
          m.month === '2026-06' ? { ...m, expenses: 1800 } : m,
        ),
      }),
    );
    expect(snapshotFingerprint(first)).not.toBe(snapshotFingerprint(second));

    const packet = JSON.stringify(toAnalysisPacket(first));
    expect(packet).toContain('Food');
    expect(packet).toContain('"id":"income"');
    expect(packet).not.toContain('note');
    expect(packet).not.toContain('email');
    expect(packet).not.toContain('contact');
    expect(packet).not.toContain('food');
    expect(Object.keys(toAnalysisPacket(first)).sort()).toEqual([
      'candidates',
      'currencyCode',
      'facts',
      'historyMonths',
      'limitations',
      'monthLabel',
    ]);
  });

  it('rejects unknown fact or action ids and keeps server-owned links', () => {
    const snapshot = buildFinancialSnapshot(base());
    expect(
      resolveNarrative(
        {
          headline: 'Over budget.',
          summary: 'Spending passed the cap.',
          insights: [
            {
              factId: 'not-real',
              sentiment: 'warning',
              title: 'Nope',
              detail: 'Invented.',
            },
            {
              factId: 'budget',
              sentiment: 'warning',
              title: 'Over budget',
              detail: 'See the budget fact.',
            },
          ],
          actions: [],
          notes: [],
        },
        snapshot,
      ),
    ).toBeNull();

    const resolved = resolveNarrative(
      {
        headline: 'Over budget.',
        summary: 'Spending passed the cap.',
        insights: [
          {
            factId: 'budget',
            sentiment: 'warning',
            title: 'Over budget',
            detail: 'Spending passed the cap.',
          },
          {
            factId: 'savings_rate',
            sentiment: 'positive',
            title: 'Still saving',
            detail: 'Net is still positive.',
          },
        ],
        actions: [
          {
            candidateId: 'review_budget',
            title: 'Adjust the budget',
            detail: 'Spending is above the cap.',
          },
        ],
        notes: [{ factId: 'goals', text: 'The trip goal is still open.' }],
      },
      snapshot,
    );
    expect(resolved?.actions[0]).toMatchObject({
      candidateId: 'review_budget',
      target: 'budget',
      categoryId: null,
    });
    expect(resolved?.insights[0]?.evidence).toContain('2400');
    expect(resolved?.notes).toEqual([
      { factId: 'goals', text: 'The trip goal is still open.' },
    ]);
  });

  it('strips template braces from labels before they can reach the prompt', () => {
    expect(safeLabel('{{income}} trip')).toBe('income trip');
    const snapshot = buildFinancialSnapshot(
      base({
        categoriesByMonth: {
          '2026-06': [{ categoryId: 'food', label: '{{Food}}', amount: 1500 }],
        },
      }),
    );
    expect(snapshot.categoryChanges[0]?.label).toBe('Food');
    expect(JSON.stringify(toAnalysisPacket(snapshot))).not.toContain('{{');
  });
});
