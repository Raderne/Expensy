namespace REM.Expensy.Backoffice.Application.Profile;

public interface IProfileService
{
    /// <summary>Returns the current user's profile, or null if the user no longer exists.</summary>
    Task<UserProfileDto?> GetProfileAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Updates display name and currency code.
    /// Returns the updated profile, or null if the user no longer exists.
    /// Throws <see cref="ArgumentException"/> if validation fails.
    /// </summary>
    Task<UserProfileDto?> UpdateProfileAsync(string userId, UpdateProfileRequest request, CancellationToken ct = default);

    /// <summary>Updates notification preference flags. Returns false if the user no longer exists.</summary>
    Task<bool> UpdateNotificationPreferencesAsync(string userId, UpdateNotificationPreferencesRequest request, CancellationToken ct = default);

    /// <summary>
    /// Validates the uploaded file, stores it via IStorage, and updates the user's Avatar URL.
    /// Returns the updated profile, or null if the user no longer exists.
    /// Throws <see cref="ArgumentException"/> for invalid file type or size.
    /// </summary>
    Task<UserProfileDto?> UpdateAvatarAsync(string userId, Stream fileStream, string fileName, string contentType, long fileSize, CancellationToken ct = default);

}
