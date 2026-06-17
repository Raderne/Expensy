import { Prisma } from '../lib/prismaTypes.js';

export interface SplitDto {
  id: string;
  contactId: string;
  contactName: string;
  contactColor: string | null;
  owedAmount: number;
  settledAmount: number;
  remaining: number;
  status: 'OWED' | 'PARTIAL' | 'SETTLED';
}

// A TransactionSplit row with its contact relation loaded.
type SplitRow = {
  id: string;
  contactId: string;
  owedAmount: Prisma.Decimal;
  settledAmount: Prisma.Decimal;
  status: 'OWED' | 'PARTIAL' | 'SETTLED';
  contact: { name: string; color: string | null };
};

export const toSplitDto = (row: SplitRow): SplitDto => {
  const owed = row.owedAmount.toNumber();
  const settled = row.settledAmount.toNumber();
  return {
    id: row.id,
    contactId: row.contactId,
    contactName: row.contact.name,
    contactColor: row.contact.color,
    owedAmount: owed,
    settledAmount: settled,
    remaining: Math.max(0, Math.round((owed - settled) * 100) / 100),
    status: row.status,
  };
};

// Recompute a split's status from its owed/settled amounts. Used after each
// reimbursement (and its reversal).
export const deriveSplitStatus = (
  owed: Prisma.Decimal,
  settled: Prisma.Decimal,
): 'OWED' | 'PARTIAL' | 'SETTLED' => {
  if (settled.lessThanOrEqualTo(0)) return 'OWED';
  if (settled.greaterThanOrEqualTo(owed)) return 'SETTLED';
  return 'PARTIAL';
};
