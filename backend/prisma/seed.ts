import { PrismaClient } from '../src/generated/prisma/client.js';

const prisma = new PrismaClient();

const CATEGORIES = [
  { key: 'income', label: 'Income', abbr: 'IN', color: '#16A34A', bgTint: '#DCFCE7', sort: 0 },
  { key: 'food',   label: 'Food',   abbr: 'FD', color: '#F56B1E', bgTint: '#FEF0E8', sort: 1 },
  { key: 'travel', label: 'Travel', abbr: 'TR', color: '#1B45D0', bgTint: '#E8EFFE', sort: 2 },
  { key: 'shop',   label: 'Shop',   abbr: 'SH', color: '#7C3AED', bgTint: '#EDE9FE', sort: 3 },
  { key: 'health', label: 'Health', abbr: 'HL', color: '#16A34A', bgTint: '#DCFCE7', sort: 4 },
  { key: 'fun',    label: 'Fun',    abbr: 'EN', color: '#DB2777', bgTint: '#FCE7F3', sort: 5 },
  { key: 'home',   label: 'Home',   abbr: 'HM', color: '#0891B2', bgTint: '#CFFAFE', sort: 6 },
  { key: 'subscriptions', label: 'Subscriptions', abbr: 'SU', color: '#8B5CF6', bgTint: '#EDE9FE', sort: 7 },
] as const;

async function main() {
  for (const cat of CATEGORIES) {
    await prisma.category.upsert({
      where: { key: cat.key },
      update: { label: cat.label, abbr: cat.abbr, color: cat.color, bgTint: cat.bgTint, sort: cat.sort },
      create: cat,
    });
  }
  console.log(`Seeded ${CATEGORIES.length} categories`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
