namespace REM.Expensy.Backoffice.Application.SavingsGoals;

/// <summary>
/// CRUD service for savings goals and milestones, scoped to the requesting user.
/// </summary>
public interface ISavingsGoalService
{
    /// <summary>
    /// Returns all savings goals owned by the specified user, including their milestones.
    /// </summary>
    Task<IReadOnlyList<SavingsGoalDto>> GetAllForUserAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns a single savings goal by ID, or <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<SavingsGoalDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Creates a new savings goal for the user. <c>CurrentAmount</c> starts at zero.
    /// </summary>
    Task<SavingsGoalDto> CreateAsync(CreateSavingsGoalRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Updates the metadata (name, target amount, target date, icon, color) of an existing savings goal.
    /// Returns <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<SavingsGoalDto?> UpdateAsync(Guid id, UpdateSavingsGoalRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Soft-deletes a savings goal. Returns <see langword="false"/> if not found or not owned by the user.
    /// </summary>
    Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Increments <c>CurrentAmount</c> by <paramref name="request"/>.<c>Amount</c>.
    /// Returns the updated DTO, or <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when the deposit would cause <c>CurrentAmount</c> to exceed <c>TargetAmount</c>.</exception>
    Task<SavingsGoalDto?> AddFundsAsync(Guid id, AddFundsRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Adds a new milestone with <c>Pending</c> status to the specified savings goal.
    /// Returns <see langword="null"/> if the goal is not found or not owned by the user.
    /// </summary>
    Task<MilestoneDto?> AddMilestoneAsync(Guid goalId, CreateMilestoneRequest request, string userId, CancellationToken ct = default);
}
