using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Dashboard;


/// <summary>
/// Implements dashboard summary queries. All reads go through <see cref="IContext"/>
/// with AsNoTracking() and the three independent aggregations run in parallel via
/// <see cref="Task.WhenAll"/> to minimise latency.
/// </summary>
public class DashboardService : IDashboardService
{
    private readonly IContext _context;

    public DashboardService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<DashboardSummaryDto> GetSummaryAsync(
        string userId,
        int month,
        int year,
        CancellationToken ct = default)
    {
        var monthStart = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd   = monthStart.AddMonths(1); // exclusive upper bound

        // Compute Mon–Sun boundaries for the current week.
        var today          = DateTime.UtcNow.Date;
        var daysFromMonday = ((int)today.DayOfWeek - (int)DayOfWeek.Monday + 7) % 7;
        var weekStart      = today.AddDays(-daysFromMonday);
        var weekEnd        = weekStart.AddDays(7); // exclusive upper bound

        // ----------------------------------------------------------------
        // Fire all three DB queries in parallel. Each produces its own SQL
        // round-trip; Task.WhenAll runs them concurrently on the async I/O
        // thread pool so total wait ≈ max(q1, q2, q3) instead of q1+q2+q3.
        // ----------------------------------------------------------------
        var monthlyTotalTask = _context.Transactions
            .AsNoTracking()
            .Where(t => t.Wallet.UserId == userId
                     && !t.IsDraft
                     && t.TransactionDate >= monthStart
                     && t.TransactionDate < monthEnd)
            .SumAsync(t => (decimal?)t.Amount, ct);

        var weeklyRawTask = _context.Transactions
            .AsNoTracking()
            .Where(t => t.Wallet.UserId == userId
                     && !t.IsDraft
                     && t.TransactionDate >= weekStart
                     && t.TransactionDate < weekEnd)
            .GroupBy(t => t.TransactionDate.Date)
            .Select(g => new { Date = g.Key, Amount = g.Sum(t => t.Amount) })
            .ToListAsync(ct);

        var recentRawTask = _context.Transactions
            .AsNoTracking()
            .Where(t => t.Wallet.UserId == userId && !t.IsDraft)
            .OrderByDescending(t => t.TransactionDate)
            .Take(10)
            .Select(t => new
            {
                Date = DateOnly.FromDateTime(t.TransactionDate),
                Dto  = new RecentTransactionDto(
                    t.Id,
                    t.Amount,
                    t.MerchantName,
                    t.Category.Name,
                    t.Category.Icon,
                    t.Category.Color,
                    t.Wallet.Name)
            })
            .ToListAsync(ct);

        await Task.WhenAll(monthlyTotalTask, weeklyRawTask, recentRawTask).ConfigureAwait(false);

        var monthlyBalance = monthlyTotalTask.Result ?? 0m;
        var weeklyRaw      = weeklyRawTask.Result;
        var recentRaw      = recentRawTask.Result;

        // ----------------------------------------------------------------
        // Zero-fill missing days so the frontend chart always gets 7 points.
        // The DB only returns days that had transactions; we fill the rest.
        // ----------------------------------------------------------------
        var dailyTotals    = weeklyRaw.ToDictionary(x => x.Date, x => x.Amount);
        var weeklySpending = BuildWeeklySpending(weekStart, dailyTotals);

        // ----------------------------------------------------------------
        // Group the 10 fetched rows by date in C# — negligible overhead
        // for 10 records and keeps the SQL simple (no GROUP BY needed).
        // ----------------------------------------------------------------
        var recentTransactions = recentRaw
            .GroupBy(r => r.Date)
            .OrderByDescending(g => g.Key)
            .Select(g => new DailyTransactionGroupDto(
                g.Key,
                g.Select(r => r.Dto).ToList()))
            .ToList();

        var totalExpenses = weeklySpending.Sum(d => d.Amount);

        return new DashboardSummaryDto(
            monthlyBalance,
            totalExpenses,
            weeklySpending,
            recentTransactions);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /// <summary>
    /// Produces exactly 7 <see cref="DailySpendingDto"/> entries (Mon–Sun) for
    /// the week starting at <paramref name="weekStart"/>, using zero for any day
    /// with no transactions.
    /// </summary>
    private static IReadOnlyList<DailySpendingDto> BuildWeeklySpending(
        DateTime weekStart,
        Dictionary<DateTime, decimal> dailyTotals)
    {
        var result = new List<DailySpendingDto>(7);

        for (var i = 0; i < 7; i++)
        {
            var day    = weekStart.AddDays(i);
            var label  = day.ToString("ddd"); // "Mon", "Tue", …
            var amount = dailyTotals.TryGetValue(day, out var amt) ? amt : 0m;
            result.Add(new DailySpendingDto(label, DateOnly.FromDateTime(day), amount));
        }

        return result;
    }
}
