namespace REM.Expensy.Backoffice.Application.Budgets;

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
