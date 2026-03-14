using REM.Expensy.Backoffice.Enums;

namespace REM.Expensy.Backoffice.Application.Budgets;

// ---------------------------------------------------------------------------
// Budget summary DTOs (Phase 3 analytics)
// ---------------------------------------------------------------------------

/// <summary>
/// Top-level response for GET /api/budgets/summary.
/// </summary>
public record BudgetSummaryDto(
    BudgetOverallProgressDto OverallProgress,
    IReadOnlyList<BudgetProgressDto> Budgets);

/// <summary>
/// Aggregate totals across all active budgets for the current user.
/// </summary>
public record BudgetOverallProgressDto(
    decimal TotalBudgeted,
    decimal TotalSpent,
    decimal PercentSpent);

/// <summary>
/// Per-budget progress row with computed insight tip.
/// </summary>
public record BudgetProgressDto(
    Guid Id,
    Guid CategoryId,
    string CategoryName,
    string CategoryIcon,
    string CategoryColor,
    decimal Limit,
    decimal Spent,
    decimal Remaining,
    decimal PercentSpent,
    BudgetStatusEnum StatusCode,
    string StatusTitle,
    string InsightTip);

// ---------------------------------------------------------------------------
// Request / response DTOs for CRUD operations
// ---------------------------------------------------------------------------

/// <summary>
/// Payload for creating a new budget.
/// </summary>
public record CreateBudgetRequest(
    Guid CategoryId,
    decimal Limit,
    string Period,
    DateOnly StartDate,
    DateOnly EndDate);

/// <summary>
/// Payload for updating an existing budget.
/// </summary>
public record UpdateBudgetRequest(
    decimal Limit,
    string Period,
    DateOnly StartDate,
    DateOnly EndDate);

/// <summary>
/// Read model returned for budget alerts.
/// </summary>
public record BudgetAlertDto(
    Guid Id,
    Guid BudgetId,
    Guid CategoryId,
    string CategoryName,
    decimal OverspentBy,
    bool IsRead,
    DateTime Created);
