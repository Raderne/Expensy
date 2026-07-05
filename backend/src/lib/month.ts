// Half-open UTC bounds [from, to) for a 'YYYY-MM' month string. UTC so month
// filtering aligns with the UTC-midnight dates stored on transactions.
export const monthRange = (month: string): { from: Date; to: Date } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  return {
    from: new Date(Date.UTC(year, m - 1, 1)),
    to: new Date(Date.UTC(year, m, 1)),
  };
};

// Human label for a 'YYYY-MM' month, e.g. 'July 2026'. Used in AI prompts.
export const monthLabel = (month: string): string => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  const name = new Date(Date.UTC(year, m - 1, 1)).toLocaleString('en-US', {
    month: 'long',
    timeZone: 'UTC',
  });
  return `${name} ${year}`;
};
