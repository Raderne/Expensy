namespace REM.Expensy.Backoffice.Application.Settings;

/// <summary>A supported currency for user account configuration.</summary>
public record CurrencyDto(
    string Code,    // ISO 4217, e.g. "USD"
    string Name,    // e.g. "US Dollar"
    string Symbol   // e.g. "$"
);

/// <summary>A billing cycle option for subscriptions.</summary>
public record SubscriptionCycleDto(
    Guid Id,
    string Code,
    string Name
);