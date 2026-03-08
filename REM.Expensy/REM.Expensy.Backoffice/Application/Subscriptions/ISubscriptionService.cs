namespace REM.Expensy.Backoffice.Application.Subscriptions;

/// <summary>
/// CRUD service for subscriptions, scoped to the requesting user.
/// </summary>
public interface ISubscriptionService
{
    /// <summary>
    /// Returns all subscriptions owned by the specified user, ordered by next renewal date ascending.
    /// </summary>
    Task<IReadOnlyList<SubscriptionDto>> GetAllForUserAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns a single subscription by ID, or <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<SubscriptionDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Creates a new subscription for the user.
    /// </summary>
    Task<SubscriptionDto> CreateAsync(CreateSubscriptionRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Updates an existing subscription. Returns <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<SubscriptionDto?> UpdateAsync(Guid id, UpdateSubscriptionRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Soft-deletes a subscription. Returns <see langword="false"/> if not found or not owned by the user.
    /// </summary>
    Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns all available subscription billing cycles (lookup data).
    /// </summary>
    Task<IReadOnlyList<SubscriptionCycleDto>> GetCyclesAsync(CancellationToken ct = default);
}
