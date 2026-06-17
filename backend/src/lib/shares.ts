import { Prisma } from './prismaTypes.js';

export interface ShareLike {
  shareType: 'AMOUNT' | 'PERCENT';
  shareValue: Prisma.Decimal;
}

// Resolve one share into a concrete owed amount for a given (positive) bill
// amount. PERCENT → amount × value / 100; AMOUNT → the fixed value. Rounded to
// cents to match the Decimal(12,2) column.
export const owedForShare = (share: ShareLike, amount: Prisma.Decimal): Prisma.Decimal => {
  const raw =
    share.shareType === 'PERCENT'
      ? amount.times(share.shareValue).div(100)
      : share.shareValue;
  return raw.toDecimalPlaces(2);
};

// Sum of all shares' owed amounts for a given bill amount.
export const totalOwedForShares = (
  shares: ShareLike[],
  amount: Prisma.Decimal,
): Prisma.Decimal =>
  shares.reduce((sum, s) => sum.plus(owedForShare(s, amount)), new Prisma.Decimal(0));
