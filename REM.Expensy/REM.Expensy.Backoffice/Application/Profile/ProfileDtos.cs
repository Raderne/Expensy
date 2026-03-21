namespace REM.Expensy.Backoffice.Application.Profile;

/// <summary>
/// The user's notification preference flags, stored as a JSON string on the User entity
/// and projected into this typed record for API responses.
/// </summary>
public record NotificationPreferencesDto(
    bool BudgetAlerts,
    bool RenewalReminders,
    bool MilestoneAlerts
);

/// <summary>
/// The full profile response returned from GET /api/profile and PUT /api/profile.
/// Never includes Identity internals (PasswordHash, SecurityStamp, ConcurrencyStamp).
/// </summary>
public record UserProfileDto(
    string UserId,
    string Email,
    string FullName,
    string? Avatar,
    string CurrencyCode,
    NotificationPreferencesDto NotificationPreferences
);

/// <summary>
/// Request body for PUT /api/profile.
/// fullName: 2–100 characters.
/// currencyCode: 3-character ISO 4217 code (e.g. "USD", "EUR").
/// </summary>
public record UpdateProfileRequest(
    string FullName,
    string CurrencyCode
);

/// <summary>
/// Request body for PATCH /api/profile/notification-preferences.
/// </summary>
public record UpdateNotificationPreferencesRequest(
    bool BudgetAlerts,
    bool RenewalReminders,
    bool MilestoneAlerts
);