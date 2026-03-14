namespace REM.Expensy.Backoffice.Application.Analytics;

/// <summary>
/// Provides read-only spending analytics for the authenticated user.
/// </summary>
public interface IAnalyticsService
{
    /// <summary>
    /// Returns a spending breakdown for the requested period compared to the previous period.
    /// </summary>
    /// <param name="userId">The authenticated user's ID.</param>
    /// <param name="period">One of: <c>week</c>, <c>month</c>, <c>year</c>.</param>
    /// <param name="referenceDate">
    ///     The date used to anchor the period window. Defaults to <see cref="DateTime.UtcNow"/> when <see langword="null"/>.
    /// </param>
    /// <param name="ct">Cancellation token.</param>
    Task<SpendingAnalyticsDto> GetSpendingAsync(
        string userId,
        string period,
        DateOnly? referenceDate,
        CancellationToken ct = default);
}
