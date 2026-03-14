namespace REM.Expensy.Backoffice.Application.Dashboard;

/// <summary>
/// Top-level response for the dashboard summary endpoint.
/// </summary>
public record DashboardSummaryDto(
    decimal MonthlyBalance,
    decimal TotalExpenses,
    IReadOnlyList<DailySpendingDto> WeeklySpending,
    IReadOnlyList<DailyTransactionGroupDto> RecentTransactions);

/// <summary>
/// Spending amount for a single calendar day within the current week.
/// </summary>
public record DailySpendingDto(
    string DayLabel,
    DateOnly Date,
    decimal Amount);

/// <summary>
/// A group of transactions that share the same calendar date, used for the recent-transactions feed.
/// </summary>
public record DailyTransactionGroupDto(
    DateOnly Date,
    IReadOnlyList<RecentTransactionDto> Transactions);

/// <summary>
/// Compact transaction projection used inside the recent-transactions feed.
/// </summary>
public record RecentTransactionDto(
    Guid Id,
    decimal Amount,
    string MerchantName,
    string CategoryName,
    string CategoryIcon,
    string CategoryColor,
    string WalletName);
