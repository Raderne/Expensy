namespace REM.Expensy.Backoffice.Application.Analytics;

/// <summary>
/// Top-level response for the spending analytics endpoint.
/// </summary>
public record SpendingAnalyticsDto(
    string PeriodLabel,
    decimal TotalSpent,
    decimal PreviousPeriodTotal,
    decimal? PercentageChangeVsPrevious,
    IReadOnlyList<CategorySpendingDto> ByCategory);

/// <summary>
/// Spending breakdown for a single category within the requested period.
/// </summary>
public record CategorySpendingDto(
    Guid CategoryId,
    string CategoryName,
    string CategoryIcon,
    string CategoryColor,
    decimal Amount,
    decimal Percentage);
