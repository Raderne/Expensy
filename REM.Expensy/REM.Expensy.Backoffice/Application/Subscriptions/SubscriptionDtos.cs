namespace REM.Expensy.Backoffice.Application.Subscriptions;

/// <summary>
/// Read model returned from subscription queries.
/// </summary>
public record SubscriptionDto(
    Guid Id,
    string Name,
    string? Icon,
    decimal Amount,
    string CycleName,
    DateOnly NextRenewal,
    bool IsActive,
    Guid CategoryId,
    string CategoryName);

/// <summary>
/// Payload for creating a new subscription.
/// </summary>
public record CreateSubscriptionRequest(
    string Name,
    string? Icon,
    decimal Amount,
    Guid CycleId,
    DateOnly NextRenewal,
    bool IsActive,
    Guid CategoryId);

/// <summary>
/// Payload for updating an existing subscription.
/// </summary>
public record UpdateSubscriptionRequest(
    string Name,
    string? Icon,
    decimal Amount,
    Guid CycleId,
    DateOnly NextRenewal,
    bool IsActive,
    Guid CategoryId);

/// <summary>
/// Lookup read model for subscription billing cycles.
/// </summary>
public record SubscriptionCycleDto(Guid Id, string Name);

/// <summary>
/// Aggregate read model returned from GET /api/subscriptions.
/// Includes a pre-calculated monthly spend total across all active subscriptions,
/// normalized to a monthly figure regardless of each subscription's billing cycle.
/// </summary>
public record SubscriptionSummaryDto(
    decimal TotalMonthlySpend,
    IReadOnlyList<SubscriptionDto> Subscriptions);