namespace REM.Expensy.Backoffice.Application.Budgets;

/// <summary>
/// CRUD service for budgets, scoped to the requesting user.
/// </summary>
public interface IBudgetService
{
    /// <summary>
    /// Returns all budgets owned by the specified user.
    /// </summary>
    Task<IReadOnlyList<BudgetDto>> GetAllForUserAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns a single budget by ID, or <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<BudgetDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Creates a new budget for the user. Status is initialised to <c>OnTrack</c> and <c>Spent</c> to zero.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when the <paramref name="request"/> Period is not a valid <see cref="Enums.PeriodEnum"/> value.</exception>
    Task<BudgetDto> CreateAsync(CreateBudgetRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Updates limit, period, and date range of an existing budget.
    /// Returns <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when the <paramref name="request"/> Period is not a valid <see cref="Enums.PeriodEnum"/> value.</exception>
    Task<BudgetDto?> UpdateAsync(Guid id, UpdateBudgetRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Soft-deletes a budget. Returns <see langword="false"/> if not found or not owned by the user.
    /// </summary>
    Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns all unread budget alerts for the specified user, ordered newest first.
    /// </summary>
    Task<IReadOnlyList<BudgetAlertDto>> GetUnreadAlertsForUserAsync(string userId, CancellationToken ct = default);
}
