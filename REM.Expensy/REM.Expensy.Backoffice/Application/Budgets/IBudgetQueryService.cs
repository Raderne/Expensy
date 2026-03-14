namespace REM.Expensy.Backoffice.Application.Budgets;

/// <summary>
/// Query service for budget read operations (monolith read side).
/// </summary>
public interface IBudgetQueryService
{
    /// <summary>
    /// Returns all budgets (excluding soft-deleted), projected to DTOs.
    /// </summary>
    Task<IReadOnlyList<BudgetDto>> GetAllAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the budget progress summary for the specified user: per-budget progress
    /// rows with computed insight tips plus aggregate totals across all active budgets.
    /// </summary>
    Task<BudgetSummaryDto> GetSummaryAsync(string userId, CancellationToken cancellationToken = default);
}
