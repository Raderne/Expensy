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
}
