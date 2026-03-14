namespace REM.Expensy.Backoffice.Application.Dashboard;

/// <summary>
/// Provides read-only aggregated dashboard data for the authenticated user.
/// </summary>
public interface IDashboardService
{
    /// <summary>
    /// Returns the dashboard summary for the given month/year: monthly balance,
    /// total expenses, day-by-day weekly spending for the current week, and
    /// the ten most recent confirmed transactions grouped by date.
    /// </summary>
    Task<DashboardSummaryDto> GetSummaryAsync(
        string userId,
        int month,
        int year,
        CancellationToken ct = default);
}
