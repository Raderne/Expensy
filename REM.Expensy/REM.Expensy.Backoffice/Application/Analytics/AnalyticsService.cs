using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Analytics;

/// <summary>
/// Implements spending analytics using a single conditional-aggregation query so that
/// current-period and previous-period totals are computed in one database round-trip.
/// </summary>
public class AnalyticsService : IAnalyticsService
{
    private readonly IContext _context;

    public AnalyticsService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<SpendingAnalyticsDto> GetSpendingAsync(
        string userId,
        string period,
        DateOnly? referenceDate,
        CancellationToken ct = default)
    {
        var anchor = referenceDate.HasValue
            ? referenceDate.Value.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc)
            : DateTime.UtcNow;

        var (currentStart, currentEnd, previousStart, previousEnd, periodLabel) =
            ComputePeriodBounds(period.ToLowerInvariant(), anchor);

        // ----------------------------------------------------------------
        // Single-query conditional aggregation: fetch both current and
        // previous totals per category in one SQL round-trip.
        //
        // The WHERE clause spans prevStart→currentEnd so EF can use an
        // index on TransactionDate; the CASE WHEN inside SUM does the
        // per-period bucketing server-side.
        // ----------------------------------------------------------------
        var rows = await _context.Transactions
            .AsNoTracking()
            .Where(t => t.Wallet.UserId == userId
                     && !t.IsDraft
                     && t.TransactionDate >= previousStart
                     && t.TransactionDate <  currentEnd)
            .GroupBy(t => new
            {
                t.CategoryId,
                t.Category.Name,
                t.Category.Icon,
                t.Category.Color
            })
            .Select(g => new
            {
                g.Key.CategoryId,
                g.Key.Name,
                g.Key.Icon,
                g.Key.Color,
                CurrentAmount = g.Sum(t =>
                    t.TransactionDate >= currentStart && t.TransactionDate < currentEnd
                        ? t.Amount
                        : 0m),
                PreviousAmount = g.Sum(t =>
                    t.TransactionDate >= previousStart && t.TransactionDate < previousEnd
                        ? t.Amount
                        : 0m)
            })
            .ToListAsync(ct)
            .ConfigureAwait(false);

        var totalSpent    = rows.Sum(r => r.CurrentAmount);
        var previousTotal = rows.Sum(r => r.PreviousAmount);

        // Percentage change: undefined (null) when previous period had no spending.
        decimal? pctChange = previousTotal == 0
            ? null
            : Math.Round((totalSpent - previousTotal) / previousTotal * 100, 2);

        // Build per-category breakdown sorted by amount descending.
        var byCategory = rows
            .Where(r => r.CurrentAmount > 0)
            .OrderByDescending(r => r.CurrentAmount)
            .Select(r => new CategorySpendingDto(
                r.CategoryId,
                r.Name,
                r.Icon,
                r.Color,
                r.CurrentAmount,
                totalSpent == 0 ? 0m : Math.Round(r.CurrentAmount / totalSpent * 100, 2)))
            .ToList();

        return new SpendingAnalyticsDto(
            periodLabel,
            totalSpent,
            previousTotal,
            pctChange,
            byCategory);
    }

    // -------------------------------------------------------------------------
    // Period computation
    // -------------------------------------------------------------------------

    /// <summary>
    /// Returns the inclusive-start / exclusive-end date ranges for the current and
    /// previous period, plus a human-readable label for the current period.
    /// </summary>
    private static (
        DateTime currentStart,
        DateTime currentEnd,
        DateTime previousStart,
        DateTime previousEnd,
        string label)
    ComputePeriodBounds(string period, DateTime anchor)
    {
        return period switch
        {
            "week" => ComputeWeekBounds(anchor),
            "year" => ComputeYearBounds(anchor),
            _      => ComputeMonthBounds(anchor) // "month" is the safe default
        };
    }

    private static (DateTime, DateTime, DateTime, DateTime, string) ComputeWeekBounds(DateTime anchor)
    {
        // Normalise to UTC midnight.
        var day            = anchor.Date;
        var daysFromMonday = ((int)day.DayOfWeek - (int)DayOfWeek.Monday + 7) % 7;
        var currentStart   = DateTime.SpecifyKind(day.AddDays(-daysFromMonday), DateTimeKind.Utc);
        var currentEnd     = currentStart.AddDays(7);
        var previousStart  = currentStart.AddDays(-7);
        var previousEnd    = currentStart;
        var label          = $"{currentStart:MMM d} – {currentEnd.AddDays(-1):MMM d, yyyy}";
        return (currentStart, currentEnd, previousStart, previousEnd, label);
    }

    private static (DateTime, DateTime, DateTime, DateTime, string) ComputeMonthBounds(DateTime anchor)
    {
        var currentStart  = new DateTime(anchor.Year, anchor.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var currentEnd    = currentStart.AddMonths(1);
        var previousStart = currentStart.AddMonths(-1);
        var previousEnd   = currentStart;
        var label         = anchor.ToString("MMMM yyyy");
        return (currentStart, currentEnd, previousStart, previousEnd, label);
    }

    private static (DateTime, DateTime, DateTime, DateTime, string) ComputeYearBounds(DateTime anchor)
    {
        var currentStart  = new DateTime(anchor.Year, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        var currentEnd    = currentStart.AddYears(1);
        var previousStart = currentStart.AddYears(-1);
        var previousEnd   = currentStart;
        var label         = anchor.Year.ToString();
        return (currentStart, currentEnd, previousStart, previousEnd, label);
    }
}
