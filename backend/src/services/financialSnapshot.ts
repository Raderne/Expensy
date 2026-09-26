import { createHash } from 'node:crypto';
import { monthLabel } from '../lib/month.js';

/** Bump when the report shape or grounding rules change so old caches miss. */
export const INSIGHTS_REPORT_VERSION = 2;
export const INSIGHTS_HISTORY_MONTHS = 6;
export const INSIGHTS_CURRENCY_CODE = 'USD';

const TOP_CATEGORIES = 5;
const TOP_COMMITMENTS = 6;
const TOP_GOALS = 5;
const TOP_UPCOMING = 8;

export type InsightSentiment = 'positive' | 'warning' | 'neutral';
export type InsightActionTarget =
  | 'transactions'
  | 'recurring_expenses'
  | 'income_sources'
  | 'goals'
  | 'budget';

export interface SnapshotMonthInput {
  month: string;
  income: number;
  expenses: number;
  /** Recorded cap, or the template cap for the focal month only. */
  budgetAmount: number | null;
}

export interface SnapshotCategoryInput {
  categoryId: string;
  label: string;
  amount: number;
}

export interface SnapshotBuildInput {
  /** Focal `YYYY-MM`. `months` must be the contiguous window ending here. */
  month: string;
  months: SnapshotMonthInput[];
  categoriesByMonth: Record<string, SnapshotCategoryInput[]>;
  recurringExpenses: { label: string; monthlyAmount: number }[];
  recurringIncome: { label: string; monthlyAmount: number }[];
  upcoming: { label: string; amount: number; dueAt: string }[];
  goals: {
    name: string;
    savedAmount: number;
    targetAmount: number;
    targetDate: string | null;
  }[];
}

export interface Scorecard {
  income: number;
  expenses: number;
  net: number;
  savingsRatePct: number | null;
  budgetAmount: number | null;
  budgetPct: number | null;
  incomeChangePct: number | null;
  expenseChangePct: number | null;
}

export interface TrendPoint {
  month: string;
  income: number;
  expenses: number;
  net: number;
  savingsRatePct: number | null;
  hasActivity: boolean;
}

export interface CategoryChange {
  categoryId: string;
  label: string;
  amount: number;
  sharePct: number;
  baselineAmount: number | null;
  changePct: number | null;
}

export interface UpcomingCommitment {
  label: string;
  amount: number;
  dueAt: string;
}

export interface Commitments {
  recurringExpenseMonthly: number;
  recurringIncomeMonthly: number;
  /** Recurring income ÷ recurring expenses × 100. Null when there are no bills. */
  coveragePct: number | null;
  upcoming: UpcomingCommitment[];
}

export interface GoalOutlookItem {
  name: string;
  savedAmount: number;
  targetAmount: number;
  progressPct: number;
  targetDate: string | null;
}

export interface DataCoverage {
  historyMonths: number;
  windowMonths: number;
  hasBudget: boolean;
  hasRecurringIncome: boolean;
  hasRecurringExpenses: boolean;
  hasGoals: boolean;
  limitations: string[];
}

export interface InsightFact {
  id: string;
  text: string;
}

export interface ActionCandidate {
  id: string;
  target: InsightActionTarget;
  categoryId: string | null;
  title: string;
  reason: string;
}

export interface FinancialSnapshot {
  version: number;
  currencyCode: typeof INSIGHTS_CURRENCY_CODE;
  month: string;
  monthLabel: string;
  scorecard: Scorecard;
  trend: TrendPoint[];
  categoryChanges: CategoryChange[];
  commitments: Commitments;
  goalOutlook: GoalOutlookItem[];
  dataCoverage: DataCoverage;
  facts: InsightFact[];
  actions: ActionCandidate[];
}

export interface AnalysisPacket {
  currencyCode: typeof INSIGHTS_CURRENCY_CODE;
  monthLabel: string;
  historyMonths: number;
  limitations: string[];
  facts: InsightFact[];
  candidates: { id: string; reason: string }[];
}

export interface AiNarrative {
  headline: string;
  summary: string;
  insights: {
    factId: string;
    sentiment: InsightSentiment;
    title: string;
    detail: string;
  }[];
  actions: { candidateId: string; title: string; detail: string }[];
  notes: { factId: string; text: string }[];
}

export interface ResolvedInsight {
  factId: string;
  sentiment: InsightSentiment;
  title: string;
  detail: string;
  evidence: string;
}

export interface ResolvedAction {
  candidateId: string;
  target: InsightActionTarget;
  categoryId: string | null;
  title: string;
  detail: string;
  evidence: string;
}

export interface ResolvedNarrative {
  headline: string;
  summary: string;
  insights: ResolvedInsight[];
  actions: ResolvedAction[];
  notes: { factId: string; text: string }[];
}

export interface InsightsReport extends ResolvedNarrative {
  version: number;
  currencyCode: typeof INSIGHTS_CURRENCY_CODE;
  month: string;
  generatedAt: string;
  aiStatus: 'generated' | 'unavailable';
  scorecard: Scorecard;
  trend: TrendPoint[];
  categoryChanges: CategoryChange[];
  commitments: Commitments;
  goalOutlook: GoalOutlookItem[];
  dataCoverage: DataCoverage;
}

const round2 = (n: number): number => Math.round(n * 100) / 100;

const money = (n: number): string => {
  const rounded = round2(n);
  return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(2);
};

/** Strip template braces so a user-chosen label cannot rewrite the prompt. */
export const safeLabel = (value: string): string =>
  value.replaceAll('{{', '').replaceAll('}}', '').trim().slice(0, 60);

export const shiftMonth = (month: string, delta: number): string => {
  const sep = month.indexOf('-');
  const year = Number(month.slice(0, sep));
  const m = Number(month.slice(sep + 1));
  const index = year * 12 + (m - 1) + delta;
  const shiftedYear = Math.floor(index / 12);
  const shiftedMonth = (((index % 12) + 12) % 12) + 1;
  return `${shiftedYear}-${String(shiftedMonth).padStart(2, '0')}`;
};

export const contiguousMonthsEnding = (month: string, count: number): string[] =>
  Array.from({ length: count }, (_, i) => shiftMonth(month, i - (count - 1)));

const pctChange = (current: number, previous: number): number | null =>
  previous > 0 ? Math.round(((current - previous) / previous) * 100) : null;

const savingsRate = (income: number, expenses: number): number | null =>
  income > 0 ? Math.round(((income - expenses) / income) * 100) : null;

const sentimentFor = (factId: string, snapshot: FinancialSnapshot): InsightSentiment => {
  const { scorecard, categoryChanges, commitments, goalOutlook } = snapshot;
  switch (factId) {
    case 'savings_rate':
      if (scorecard.savingsRatePct == null) return 'neutral';
      if (scorecard.savingsRatePct >= 10) return 'positive';
      return scorecard.savingsRatePct < 0 ? 'warning' : 'neutral';
    case 'budget':
      if (scorecard.budgetPct == null) return 'neutral';
      return scorecard.budgetPct > 100 ? 'warning' : 'positive';
    case 'expense_change':
      if (scorecard.expenseChangePct == null) return 'neutral';
      if (scorecard.expenseChangePct > 15) return 'warning';
      return scorecard.expenseChangePct < -10 ? 'positive' : 'neutral';
    case 'income_change':
      if (scorecard.incomeChangePct == null) return 'neutral';
      if (scorecard.incomeChangePct > 10) return 'positive';
      return scorecard.incomeChangePct < -10 ? 'warning' : 'neutral';
    case 'recurring_coverage':
      if (commitments.coveragePct == null) return 'neutral';
      return commitments.coveragePct < 100 ? 'warning' : 'positive';
    case 'top_category':
      return (categoryChanges[0]?.sharePct ?? 0) >= 40 ? 'warning' : 'neutral';
    case 'category_shift': {
      const shift = [...categoryChanges].sort(
        (a, b) => Math.abs(b.changePct ?? 0) - Math.abs(a.changePct ?? 0),
      )[0];
      if (shift?.changePct == null) return 'neutral';
      if (shift.changePct > 25) return 'warning';
      return shift.changePct < -15 ? 'positive' : 'neutral';
    }
    case 'upcoming': {
      const total = commitments.upcoming.reduce((sum, item) => sum + item.amount, 0);
      return total > Math.max(scorecard.net, 0) ? 'warning' : 'neutral';
    }
    case 'goals':
      return goalOutlook.some((g) => g.progressPct > 0) ? 'positive' : 'neutral';
    default:
      return 'neutral';
  }
};

const FACT_TITLES: Record<string, string> = {
  income: 'Income',
  expenses: 'Spending',
  net: 'Net',
  savings_rate: 'Savings rate',
  budget: 'Budget',
  expense_change: 'Spending change',
  income_change: 'Income change',
  top_category: 'Largest category',
  category_shift: 'Category change',
  recurring_coverage: 'Recurring cash flow',
  upcoming: 'Upcoming bills',
  goals: 'Goals',
};

export const buildFinancialSnapshot = (input: SnapshotBuildInput): FinancialSnapshot => {
  const focal = input.months[input.months.length - 1];
  if (!focal || focal.month !== input.month || input.months.length === 0) {
    throw new Error('snapshot window must end on the focal month');
  }
  const previous = input.months[input.months.length - 2];
  const label = monthLabel(input.month);
  const income = round2(focal.income);
  const expenses = round2(focal.expenses);
  const net = round2(income - expenses);
  const budgetAmount =
    focal.budgetAmount != null && focal.budgetAmount > 0 ? round2(focal.budgetAmount) : null;
  const scorecard: Scorecard = {
    income,
    expenses,
    net,
    savingsRatePct: savingsRate(income, expenses),
    budgetAmount,
    budgetPct:
      budgetAmount != null && budgetAmount > 0
        ? Math.round((expenses / budgetAmount) * 100)
        : null,
    incomeChangePct: previous ? pctChange(income, previous.income) : null,
    expenseChangePct: previous ? pctChange(expenses, previous.expenses) : null,
  };

  const trend: TrendPoint[] = input.months.map((m) => ({
    month: m.month,
    income: round2(m.income),
    expenses: round2(m.expenses),
    net: round2(m.income - m.expenses),
    savingsRatePct: savingsRate(m.income, m.expenses),
    hasActivity: m.income > 0 || m.expenses > 0,
  }));

  const priorActive = input.months.slice(0, -1).filter((m) => m.expenses > 0);
  const focalCategories = [...(input.categoriesByMonth[input.month] ?? [])]
    .filter((c) => c.amount > 0)
    .sort((a, b) => b.amount - a.amount)
    .slice(0, TOP_CATEGORIES);
  const categoryChanges: CategoryChange[] = focalCategories.map((cat) => {
    const samples =
      priorActive.length === 0
        ? null
        : priorActive.map((m) => {
            const match = (input.categoriesByMonth[m.month] ?? []).find(
              (c) => c.categoryId === cat.categoryId,
            );
            return match?.amount ?? 0;
          });
    const baseline =
      samples == null ? null : round2(samples.reduce((sum, n) => sum + n, 0) / samples.length);
    return {
      categoryId: cat.categoryId,
      label: safeLabel(cat.label) || 'Category',
      amount: round2(cat.amount),
      sharePct: expenses > 0 ? Math.round((cat.amount / expenses) * 100) : 0,
      baselineAmount: baseline,
      changePct: baseline != null && baseline > 0 ? pctChange(cat.amount, baseline) : null,
    };
  });

  const expensesRanked = [...input.recurringExpenses]
    .filter((r) => r.monthlyAmount > 0)
    .sort((a, b) => b.monthlyAmount - a.monthlyAmount)
    .slice(0, TOP_COMMITMENTS);
  const incomeRanked = [...input.recurringIncome]
    .filter((r) => r.monthlyAmount > 0)
    .sort((a, b) => b.monthlyAmount - a.monthlyAmount)
    .slice(0, TOP_COMMITMENTS);
  const recurringExpenseMonthly = round2(
    input.recurringExpenses.reduce((sum, r) => sum + Math.max(0, r.monthlyAmount), 0),
  );
  const recurringIncomeMonthly = round2(
    input.recurringIncome.reduce((sum, r) => sum + Math.max(0, r.monthlyAmount), 0),
  );
  const commitments: Commitments = {
    recurringExpenseMonthly,
    recurringIncomeMonthly,
    coveragePct:
      recurringExpenseMonthly > 0
        ? Math.round((recurringIncomeMonthly / recurringExpenseMonthly) * 100)
        : null,
    upcoming: input.upcoming.slice(0, TOP_UPCOMING).map((item) => ({
      label: safeLabel(item.label) || 'Bill',
      amount: round2(item.amount),
      dueAt: item.dueAt,
    })),
  };

  const goalOutlook: GoalOutlookItem[] = [...input.goals]
    .map((g) => {
      const target = round2(Math.max(0, g.targetAmount));
      const saved = round2(Math.max(0, g.savedAmount));
      return {
        name: safeLabel(g.name) || 'Goal',
        savedAmount: saved,
        targetAmount: target,
        progressPct: target > 0 ? Math.round((saved / target) * 100) : 0,
        targetDate: g.targetDate,
      };
    })
    .sort((a, b) => b.targetAmount - b.savedAmount - (a.targetAmount - a.savedAmount))
    .slice(0, TOP_GOALS);

  const historyMonths = trend.filter((p) => p.hasActivity).length;
  const limitations: string[] = [];
  if (historyMonths < 3) {
    limitations.push(
      `Only ${historyMonths} of ${input.months.length} months in this window have activity, so comparisons are limited.`,
    );
  }
  if (budgetAmount == null) {
    limitations.push('No monthly budget is set, so budget adherence is not included.');
  }
  if (scorecard.savingsRatePct == null) {
    limitations.push('Savings rate needs income in the selected month.');
  }
  if (recurringIncomeMonthly === 0 && recurringExpenseMonthly === 0) {
    limitations.push('Recurring income and bills are not set, so committed cash flow is incomplete.');
  }
  if (goalOutlook.length === 0) {
    limitations.push('Goals are not included because none are set.');
  }
  limitations.push(
    'Goals and upcoming bills reflect current settings, not only the selected month.',
  );
  limitations.push(
    'This is educational budgeting guidance, not investment, tax, credit, or legal advice.',
  );

  const dataCoverage: DataCoverage = {
    historyMonths,
    windowMonths: input.months.length,
    hasBudget: budgetAmount != null,
    hasRecurringIncome: recurringIncomeMonthly > 0,
    hasRecurringExpenses: recurringExpenseMonthly > 0,
    hasGoals: goalOutlook.length > 0,
    limitations,
  };

  const facts: InsightFact[] = [
    { id: 'income', text: `Income in ${label} is ${money(income)} USD.` },
    { id: 'expenses', text: `Spending in ${label} is ${money(expenses)} USD.` },
    { id: 'net', text: `Net (income minus spending) in ${label} is ${money(net)} USD.` },
  ];
  if (scorecard.savingsRatePct != null) {
    facts.push({
      id: 'savings_rate',
      text: `Savings rate in ${label} is ${scorecard.savingsRatePct}% (net divided by income).`,
    });
  }
  if (budgetAmount != null && scorecard.budgetPct != null) {
    facts.push({
      id: 'budget',
      text: `The ${label} budget is ${money(budgetAmount)} USD and spending is ${scorecard.budgetPct}% of it.`,
    });
  }
  if (previous && scorecard.expenseChangePct != null) {
    facts.push({
      id: 'expense_change',
      text: `Spending changed ${scorecard.expenseChangePct}% versus ${monthLabel(previous.month)}.`,
    });
  }
  if (previous && scorecard.incomeChangePct != null) {
    facts.push({
      id: 'income_change',
      text: `Income changed ${scorecard.incomeChangePct}% versus ${monthLabel(previous.month)}.`,
    });
  }
  const top = categoryChanges[0];
  if (top) {
    facts.push({
      id: 'top_category',
      text: `${top.label} is the largest category at ${money(top.amount)} USD (${top.sharePct}% of spending).`,
    });
  }
  const shift = [...categoryChanges]
    .filter((c) => c.changePct != null)
    .sort((a, b) => Math.abs(b.changePct ?? 0) - Math.abs(a.changePct ?? 0))[0];
  if (
    shift &&
    shift.changePct != null &&
    shift.baselineAmount != null &&
    Math.abs(shift.changePct) >= 15
  ) {
    facts.push({
      id: 'category_shift',
      text: `${shift.label} is ${shift.changePct}% versus its ${money(shift.baselineAmount)} USD average in earlier months of this window.`,
    });
  }
  if (recurringExpenseMonthly > 0 || recurringIncomeMonthly > 0) {
    const expenseList =
      expensesRanked.map((r) => `${safeLabel(r.label)} ${money(r.monthlyAmount)}`).join(', ') ||
      'none';
    const incomeList =
      incomeRanked.map((r) => `${safeLabel(r.label)} ${money(r.monthlyAmount)}`).join(', ') ||
      'none';
    facts.push({
      id: 'recurring_coverage',
      text:
        `Recurring income is ${money(recurringIncomeMonthly)} USD/mo (${incomeList}) and recurring bills are ${money(recurringExpenseMonthly)} USD/mo (${expenseList}).` +
        (commitments.coveragePct == null
          ? ''
          : ` Recurring income covers ${commitments.coveragePct}% of recurring bills.`),
    });
  }
  if (commitments.upcoming.length > 0) {
    const total = round2(commitments.upcoming.reduce((sum, item) => sum + item.amount, 0));
    facts.push({
      id: 'upcoming',
      text: `Upcoming bills in the next 30 days total ${money(total)} USD across ${commitments.upcoming.length} charges.`,
    });
  }
  if (goalOutlook.length > 0) {
    const described = goalOutlook
      .map((g) => `${g.name} ${money(g.savedAmount)} of ${money(g.targetAmount)} (${g.progressPct}%)`)
      .join('; ');
    facts.push({
      id: 'goals',
      text: `Current goals (not tied to the ledger): ${described}.`,
    });
  }

  const actions: ActionCandidate[] = [];
  if (scorecard.budgetPct != null && scorecard.budgetPct > 100 && budgetAmount != null) {
    actions.push({
      id: 'review_budget',
      target: 'budget',
      categoryId: null,
      title: 'Bring spending back under budget',
      reason: `Spending is ${money(expenses)} USD, ${scorecard.budgetPct}% of the ${money(budgetAmount)} USD budget.`,
    });
  } else if (budgetAmount == null) {
    actions.push({
      id: 'set_budget',
      target: 'budget',
      categoryId: null,
      title: 'Set a monthly spending budget',
      reason: `Spending in ${label} is ${money(expenses)} USD and no budget is set.`,
    });
  }
  const jumped = [...categoryChanges]
    .filter((c) => c.changePct != null && c.changePct >= 25)
    .sort((a, b) => (b.changePct ?? 0) - (a.changePct ?? 0))[0];
  const categoryFocus = top && top.sharePct >= 35 ? top : jumped;
  if (categoryFocus) {
    actions.push({
      id: 'review_category',
      target: 'transactions',
      categoryId: categoryFocus.categoryId,
      title: `Review ${categoryFocus.label}`,
      reason: `${categoryFocus.label} is ${money(categoryFocus.amount)} USD, ${categoryFocus.sharePct}% of spending${
        categoryFocus.changePct != null
          ? ` (${categoryFocus.changePct}% versus the earlier-month average)`
          : ''
      }.`,
    });
  }
  if (
    recurringExpenseMonthly > 0 &&
    (recurringIncomeMonthly === 0 || (commitments.coveragePct != null && commitments.coveragePct < 100))
  ) {
    actions.push({
      id: 'review_recurring',
      target: 'recurring_expenses',
      categoryId: null,
      title: 'Review recurring bills',
      reason: `Recurring bills are ${money(recurringExpenseMonthly)} USD/mo and recurring income covers ${commitments.coveragePct ?? 0}% of them.`,
    });
  }
  if (recurringIncomeMonthly === 0 && income > 0) {
    actions.push({
      id: 'record_income',
      target: 'income_sources',
      categoryId: null,
      title: 'Record regular income',
      reason: `${label} has ${money(income)} USD of income and no recurring income source on file.`,
    });
  }
  const upcomingTotal = commitments.upcoming.reduce((sum, item) => sum + item.amount, 0);
  if (upcomingTotal > Math.max(net, 0) && commitments.upcoming.length > 0) {
    actions.push({
      id: 'plan_upcoming',
      target: 'recurring_expenses',
      categoryId: null,
      title: 'Plan for upcoming bills',
      reason: `Bills due in the next 30 days total ${money(upcomingTotal)} USD, above this month's ${money(net)} USD net.`,
    });
  }
  if (goalOutlook.some((g) => g.savedAmount < g.targetAmount) && net > 0) {
    actions.push({
      id: 'fund_goals',
      target: 'goals',
      categoryId: null,
      title: 'Put surplus toward a goal',
      reason: `${label} net is ${money(net)} USD and at least one goal is still short of its target.`,
    });
  }

  return {
    version: INSIGHTS_REPORT_VERSION,
    currencyCode: INSIGHTS_CURRENCY_CODE,
    month: input.month,
    monthLabel: label,
    scorecard,
    trend,
    categoryChanges,
    commitments,
    goalOutlook,
    dataCoverage,
    facts,
    actions: actions.slice(0, 6),
  };
};

/** Prompt payload: ids and sentences only. No notes, contacts, or ledger rows. */
export const toAnalysisPacket = (snapshot: FinancialSnapshot): AnalysisPacket => ({
  currencyCode: snapshot.currencyCode,
  monthLabel: snapshot.monthLabel,
  historyMonths: snapshot.dataCoverage.historyMonths,
  limitations: snapshot.dataCoverage.limitations,
  facts: snapshot.facts,
  candidates: snapshot.actions.map((action) => ({ id: action.id, reason: action.reason })),
});

export const snapshotFingerprint = (snapshot: FinancialSnapshot): string => {
  const payload = {
    version: snapshot.version,
    month: snapshot.month,
    scorecard: snapshot.scorecard,
    trend: snapshot.trend,
    categoryChanges: snapshot.categoryChanges,
    commitments: snapshot.commitments,
    goalOutlook: snapshot.goalOutlook,
  };
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex').slice(0, 16);
};

const titleFor = (factId: string): string => FACT_TITLES[factId] ?? 'Observation';

export const fallbackNarrative = (snapshot: FinancialSnapshot): ResolvedNarrative => {
  const { scorecard } = snapshot;
  const label = snapshot.monthLabel;
  let headline: string;
  if (scorecard.savingsRatePct != null && scorecard.savingsRatePct >= 20) {
    headline = `You kept ${scorecard.savingsRatePct}% of income in ${label}.`;
  } else if (scorecard.savingsRatePct != null && scorecard.savingsRatePct < 0) {
    headline = `Spending was higher than income in ${label}.`;
  } else if (scorecard.budgetPct != null && scorecard.budgetPct > 100) {
    headline = `Spending is over budget in ${label}.`;
  } else if (scorecard.income === 0) {
    headline = `${label} has spending and no recorded income.`;
  } else {
    headline = `${label} net is ${money(scorecard.net)} USD.`;
  }

  const insights = snapshot.facts.slice(0, 4).map((fact) => ({
    factId: fact.id,
    sentiment: sentimentFor(fact.id, snapshot),
    title: titleFor(fact.id),
    detail: fact.text,
    evidence: fact.text,
  }));

  const goalFact = snapshot.facts.find((fact) => fact.id === 'goals');
  return {
    headline,
    summary: `${label}: income ${money(scorecard.income)} USD, spending ${money(scorecard.expenses)} USD, net ${money(scorecard.net)} USD.`,
    insights,
    actions: snapshot.actions.slice(0, 3).map((action) => ({
      candidateId: action.id,
      target: action.target,
      categoryId: action.categoryId,
      title: action.title,
      detail: action.reason,
      evidence: action.reason,
    })),
    notes: goalFact ? [{ factId: 'goals', text: goalFact.text }] : [],
  };
};

/**
 * Keep model prose only when every cited id exists. Unknown references drop the
 * whole narrative so invented evidence cannot ship beside real figures.
 */
export const resolveNarrative = (
  ai: AiNarrative,
  snapshot: FinancialSnapshot,
): ResolvedNarrative | null => {
  const facts = new Map(snapshot.facts.map((fact) => [fact.id, fact]));
  const actions = new Map(snapshot.actions.map((action) => [action.id, action]));
  if (!ai.headline.trim() || !ai.summary.trim()) return null;

  const seenFacts = new Set<string>();
  const insights: ResolvedInsight[] = [];
  for (const item of ai.insights) {
    const fact = facts.get(item.factId);
    if (!fact || seenFacts.has(item.factId)) return null;
    seenFacts.add(item.factId);
    insights.push({
      factId: item.factId,
      sentiment: item.sentiment,
      title: item.title.trim() || titleFor(item.factId),
      detail: item.detail.trim() || fact.text,
      evidence: fact.text,
    });
  }
  if (insights.length < 2) return null;

  const seenActions = new Set<string>();
  const resolvedActions: ResolvedAction[] = [];
  for (const item of ai.actions) {
    const candidate = actions.get(item.candidateId);
    if (!candidate || seenActions.has(item.candidateId)) return null;
    seenActions.add(item.candidateId);
    resolvedActions.push({
      candidateId: candidate.id,
      target: candidate.target,
      categoryId: candidate.categoryId,
      title: item.title.trim() || candidate.title,
      detail: item.detail.trim() || candidate.reason,
      evidence: candidate.reason,
    });
  }

  const notes: { factId: string; text: string }[] = [];
  for (const note of ai.notes) {
    if (!facts.has(note.factId) || !note.text.trim()) return null;
    notes.push({ factId: note.factId, text: note.text.trim() });
  }

  return {
    headline: ai.headline.trim(),
    summary: ai.summary.trim(),
    insights,
    actions: resolvedActions.slice(0, 3),
    notes: notes.slice(0, 2),
  };
};

export const assembleReport = (
  snapshot: FinancialSnapshot,
  narrative: ResolvedNarrative,
  aiStatus: InsightsReport['aiStatus'],
  generatedAt: string,
): InsightsReport => ({
  version: snapshot.version,
  currencyCode: snapshot.currencyCode,
  month: snapshot.month,
  generatedAt,
  aiStatus,
  headline: narrative.headline,
  summary: narrative.summary,
  insights: narrative.insights,
  actions: narrative.actions,
  notes: narrative.notes,
  scorecard: snapshot.scorecard,
  trend: snapshot.trend,
  categoryChanges: snapshot.categoryChanges,
  commitments: snapshot.commitments,
  goalOutlook: snapshot.goalOutlook,
  dataCoverage: snapshot.dataCoverage,
});
