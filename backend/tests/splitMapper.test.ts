import { describe, expect, it } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';
import { deriveSplitStatus, toSplitDto } from '../src/services/splitMapper.js';

const d = (n: number | string) => new Prisma.Decimal(n);

describe('deriveSplitStatus', () => {
  it('is OWED when nothing is settled', () => {
    expect(deriveSplitStatus(d(175), d(0))).toBe('OWED');
  });

  it('is PARTIAL when some but not all is settled', () => {
    expect(deriveSplitStatus(d(175), d(100))).toBe('PARTIAL');
  });

  it('is SETTLED when the full amount is repaid', () => {
    expect(deriveSplitStatus(d(175), d(175))).toBe('SETTLED');
  });

  it('is SETTLED when settled exceeds owed (defensive)', () => {
    expect(deriveSplitStatus(d(175), d(200))).toBe('SETTLED');
  });
});

describe('toSplitDto', () => {
  it('computes the remaining balance', () => {
    const dto = toSplitDto({
      id: 's1',
      contactId: 'c1',
      owedAmount: d(175),
      settledAmount: d(100),
      status: 'PARTIAL',
      contact: { name: 'Brother', color: '#1B45D0' },
    });
    expect(dto).toMatchObject({
      contactName: 'Brother',
      owedAmount: 175,
      settledAmount: 100,
      remaining: 75,
      status: 'PARTIAL',
    });
  });

  it('never reports a negative remaining', () => {
    const dto = toSplitDto({
      id: 's1',
      contactId: 'c1',
      owedAmount: d(175),
      settledAmount: d(175),
      status: 'SETTLED',
      contact: { name: 'Brother', color: null },
    });
    expect(dto.remaining).toBe(0);
  });
});
