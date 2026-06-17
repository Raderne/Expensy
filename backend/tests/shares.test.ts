import { describe, expect, it } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';
import { owedForShare, totalOwedForShares } from '../src/lib/shares.js';

const d = (n: number | string) => new Prisma.Decimal(n);

describe('owedForShare', () => {
  it('resolves a PERCENT share against the bill amount', () => {
    const owed = owedForShare({ shareType: 'PERCENT', shareValue: d(50) }, d(350));
    expect(owed.toNumber()).toBe(175);
  });

  it('returns the fixed value for an AMOUNT share', () => {
    const owed = owedForShare({ shareType: 'AMOUNT', shareValue: d(175) }, d(350));
    expect(owed.toNumber()).toBe(175);
  });

  it('rounds PERCENT results to cents', () => {
    // 33.333% of 100 = 33.333 → 33.33
    const owed = owedForShare({ shareType: 'PERCENT', shareValue: d('33.333') }, d(100));
    expect(owed.toNumber()).toBe(33.33);
  });
});

describe('totalOwedForShares', () => {
  it('sums mixed AMOUNT and PERCENT shares', () => {
    const total = totalOwedForShares(
      [
        { shareType: 'PERCENT', shareValue: d(25) }, // 25 of 100
        { shareType: 'AMOUNT', shareValue: d(10) }, // 10
      ],
      d(100),
    );
    expect(total.toNumber()).toBe(35);
  });

  it('is zero for no shares', () => {
    expect(totalOwedForShares([], d(100)).toNumber()).toBe(0);
  });
});
