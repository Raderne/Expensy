// Pure cadence math for recurring expenses. No Prisma, no I/O — easy to test.
//
// Conventions:
//   - All dates are treated as wall-clock dates (no time-of-day). Callers may
//     pass a Date with any time component; helpers normalize to start-of-day
//     before computing.
//   - All bounds use start-of-day comparison.

export type RecurrenceFrequency = 'WEEKLY' | 'BIWEEKLY' | 'MONTHLY' | 'CUSTOM';

export interface RecurrenceRule {
  frequency: RecurrenceFrequency;
  anchorDate: Date;
  intervalDays?: number | null;
}

const MS_PER_DAY = 86_400_000;

const startOfDay = (d: Date): Date =>
  new Date(d.getFullYear(), d.getMonth(), d.getDate());

const addDays = (d: Date, days: number): Date => {
  const next = new Date(d);
  next.setDate(next.getDate() + days);
  return next;
};

const lastDayOfMonth = (year: number, monthIndex: number): number =>
  new Date(year, monthIndex + 1, 0).getDate();

// Add `months` calendar months to `d`, clamping the day to the target month's
// last day. e.g. anchor Jan 31 + 1 month = Feb 28 (or 29 in a leap year).
const addMonthsClamped = (d: Date, months: number): Date => {
  const target = d.getMonth() + months;
  const year = d.getFullYear() + Math.floor(target / 12);
  const month = ((target % 12) + 12) % 12;
  const day = Math.min(d.getDate(), lastDayOfMonth(year, month));
  return new Date(year, month, day);
};

const stepDays = (frequency: RecurrenceFrequency, intervalDays?: number | null): number => {
  switch (frequency) {
    case 'WEEKLY':
      return 7;
    case 'BIWEEKLY':
      return 14;
    case 'CUSTOM':
      if (!intervalDays || intervalDays < 1) {
        throw new Error('intervalDays is required for CUSTOM frequency');
      }
      return intervalDays;
    case 'MONTHLY':
      return 0; // handled separately via addMonthsClamped
  }
};

// kth occurrence of the sequence (k = 0 → anchor).
const occurrenceAt = (rule: RecurrenceRule, k: number): Date => {
  const anchor = startOfDay(rule.anchorDate);
  if (rule.frequency === 'MONTHLY') return addMonthsClamped(anchor, k);
  return addDays(anchor, stepDays(rule.frequency, rule.intervalDays) * k);
};

// Smallest k such that occurrenceAt(rule, k) >= target.
const firstIndexOnOrAfter = (rule: RecurrenceRule, target: Date): number => {
  const anchor = startOfDay(rule.anchorDate);
  const cutoff = startOfDay(target);
  if (anchor >= cutoff) return 0;

  if (rule.frequency === 'MONTHLY') {
    // Estimate then correct — calendar months are uneven.
    const estimate =
      (cutoff.getFullYear() - anchor.getFullYear()) * 12 +
      (cutoff.getMonth() - anchor.getMonth());
    let k = Math.max(0, estimate - 1);
    while (occurrenceAt(rule, k) < cutoff) k += 1;
    return k;
  }

  const step = stepDays(rule.frequency, rule.intervalDays);
  const diffDays = Math.floor((cutoff.getTime() - anchor.getTime()) / MS_PER_DAY);
  return Math.ceil(diffDays / step);
};

// Next occurrence strictly > `after`.
export const nextOccurrence = (rule: RecurrenceRule, after: Date): Date => {
  const cutoff = startOfDay(after);
  let k = firstIndexOnOrAfter(rule, cutoff);
  if (occurrenceAt(rule, k) <= cutoff) k += 1;
  return occurrenceAt(rule, k);
};

// All occurrences in [from, until] (inclusive day bounds).
export const occurrencesBetween = (
  rule: RecurrenceRule,
  from: Date,
  until: Date,
): Date[] => {
  const end = startOfDay(until);
  let k = firstIndexOnOrAfter(rule, from);
  const out: Date[] = [];
  // Safety bound to avoid runaway loops if a rule misbehaves.
  let safety = 10_000;
  while (safety-- > 0) {
    const occ = occurrenceAt(rule, k);
    if (occ > end) break;
    out.push(occ);
    k += 1;
  }
  return out;
};

// Next `limit` occurrences with start-of-day >= `from`.
export const upcomingOccurrences = (
  rule: RecurrenceRule,
  from: Date,
  limit: number,
): Date[] => {
  if (limit <= 0) return [];
  let k = firstIndexOnOrAfter(rule, from);
  const out: Date[] = [];
  while (out.length < limit) {
    out.push(occurrenceAt(rule, k));
    k += 1;
  }
  return out;
};
