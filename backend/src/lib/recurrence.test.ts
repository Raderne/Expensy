import { describe, expect, it } from 'vitest';
import {
  nextOccurrence,
  occurrencesBetween,
  upcomingOccurrences,
  type RecurrenceRule,
} from './recurrence.js';

const d = (s: string): Date => new Date(s + 'T00:00:00');

describe('recurrence', () => {
  describe('WEEKLY', () => {
    const rule: RecurrenceRule = { frequency: 'WEEKLY', anchorDate: d('2026-05-01') };

    it('returns anchor when from is before it', () => {
      const [first] = upcomingOccurrences(rule, d('2026-04-20'), 1);
      expect(first?.toISOString()).toBe(d('2026-05-01').toISOString());
    });

    it('walks weekly from anchor', () => {
      const out = upcomingOccurrences(rule, d('2026-05-01'), 4).map((x) => x.toISOString());
      expect(out).toEqual([
        d('2026-05-01').toISOString(),
        d('2026-05-08').toISOString(),
        d('2026-05-15').toISOString(),
        d('2026-05-22').toISOString(),
      ]);
    });

    it('nextOccurrence is strictly after', () => {
      expect(nextOccurrence(rule, d('2026-05-08')).toISOString()).toBe(
        d('2026-05-15').toISOString(),
      );
    });

    it('occurrencesBetween includes both ends', () => {
      const out = occurrencesBetween(rule, d('2026-05-01'), d('2026-05-22')).map((x) =>
        x.toISOString(),
      );
      expect(out).toHaveLength(4);
      expect(out[0]).toBe(d('2026-05-01').toISOString());
      expect(out[3]).toBe(d('2026-05-22').toISOString());
    });
  });

  describe('BIWEEKLY', () => {
    const rule: RecurrenceRule = { frequency: 'BIWEEKLY', anchorDate: d('2026-05-05') };

    it('walks by 14 days', () => {
      const out = upcomingOccurrences(rule, d('2026-05-05'), 3).map((x) => x.toISOString());
      expect(out).toEqual([
        d('2026-05-05').toISOString(),
        d('2026-05-19').toISOString(),
        d('2026-06-02').toISOString(),
      ]);
    });
  });

  describe('MONTHLY', () => {
    it('clamps Jan 31 → Feb 28 in non-leap years', () => {
      const rule: RecurrenceRule = { frequency: 'MONTHLY', anchorDate: d('2026-01-31') };
      const out = upcomingOccurrences(rule, d('2026-01-31'), 3).map((x) => x.toISOString());
      expect(out).toEqual([
        d('2026-01-31').toISOString(),
        d('2026-02-28').toISOString(),
        d('2026-03-31').toISOString(),
      ]);
    });

    it('clamps Jan 31 → Feb 29 in a leap year', () => {
      const rule: RecurrenceRule = { frequency: 'MONTHLY', anchorDate: d('2024-01-31') };
      const out = upcomingOccurrences(rule, d('2024-01-31'), 2).map((x) => x.toISOString());
      expect(out).toEqual([
        d('2024-01-31').toISOString(),
        d('2024-02-29').toISOString(),
      ]);
    });

    it('honors a from-date in the middle of the sequence', () => {
      const rule: RecurrenceRule = { frequency: 'MONTHLY', anchorDate: d('2026-01-15') };
      const out = upcomingOccurrences(rule, d('2026-03-20'), 2).map((x) => x.toISOString());
      expect(out).toEqual([
        d('2026-04-15').toISOString(),
        d('2026-05-15').toISOString(),
      ]);
    });
  });

  describe('CUSTOM', () => {
    const rule: RecurrenceRule = {
      frequency: 'CUSTOM',
      anchorDate: d('2026-01-01'),
      intervalDays: 45,
    };

    it('walks by intervalDays', () => {
      const out = upcomingOccurrences(rule, d('2026-01-01'), 3).map((x) => x.toISOString());
      expect(out).toEqual([
        d('2026-01-01').toISOString(),
        d('2026-02-15').toISOString(),
        d('2026-04-01').toISOString(),
      ]);
    });

    it('throws if intervalDays missing', () => {
      const broken: RecurrenceRule = { frequency: 'CUSTOM', anchorDate: d('2026-01-01') };
      expect(() => upcomingOccurrences(broken, d('2026-01-01'), 1)).toThrow();
    });
  });

  describe('occurrencesBetween', () => {
    it('returns empty when until < from', () => {
      const rule: RecurrenceRule = { frequency: 'WEEKLY', anchorDate: d('2026-01-01') };
      expect(occurrencesBetween(rule, d('2026-02-01'), d('2026-01-15'))).toEqual([]);
    });

    it('returns empty when range is before anchor', () => {
      const rule: RecurrenceRule = { frequency: 'WEEKLY', anchorDate: d('2026-05-01') };
      expect(occurrencesBetween(rule, d('2026-01-01'), d('2026-04-30'))).toEqual([]);
    });
  });
});
