using Microsoft.AspNetCore.Identity;
using Newtonsoft.Json;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Profile;

public class ProfileService(UserManager<User> userManager) : IProfileService
{
    private readonly UserManager<User> _userManager = userManager;
    private readonly IStorage _storage;

    private static readonly long MaxAvatarSizeBytes = 5 * 1024 * 1024; // 5 MB
    private static readonly byte[] JpegMagicBytes = [0xFF, 0xD8, 0xFF];
    private static readonly byte[] PngMagicBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    public async Task<UserProfileDto?> GetProfileAsync(string userId, CancellationToken ct = default)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null) return null;

        return MapToDto(user);
    }

    public async Task<UserProfileDto?> UpdateAvatarAsync(string userId, Stream fileStream, string fileName, string contentType, long fileSize, CancellationToken ct = default)
    {
        // 1. Size guard
        if (fileSize > MaxAvatarSizeBytes)
            throw new ArgumentException("Avatar file must not exceed 5 MB.", nameof(fileSize));

        // 2. Read magic bytes — peek at the start of the stream
        var header = new byte[8]; // Max length of our magic byte signatures
        int bytesRead = await fileStream.ReadAsync(header, 0, header.Length, ct).ConfigureAwait(false);

        string? detectedMime = DetectMimeType(header, bytesRead);
        if (detectedMime is null)
            throw new ArgumentException("Only JPEG and PNG images are accepted.", nameof(fileStream));

        // 3. Reset the stream so IStorage uploads the full file, not just bytes 8+
        fileStream.Seek(0, SeekOrigin.Begin);

        // 4. Upload and get back the public URL
        // TODO : Save file to storage and get URL.
        //var url = await _storage.SaveFileAsync(fileStream, fileName, detectedMime, ct).ConfigureAwait(false);

        // 5. Persist the URL on the user
        var user = await _userManager.FindByIdAsync(userId).ConfigureAwait(false);
        if (user is null) return null;

        user.Avatar = fileName;

        var result = await _userManager.UpdateAsync(user).ConfigureAwait(false);
        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to update avatar: {errors}");
        }

        return MapToDto(user);
    }

    public async Task<bool> UpdateNotificationPreferencesAsync(string userId, UpdateNotificationPreferencesRequest request, CancellationToken ct = default)
    {
        var user = await _userManager.FindByIdAsync(userId).ConfigureAwait(false);
        if (user is null) return false;

        var preferencesJson = JsonConvert.SerializeObject(new
        {
            request.BudgetAlerts,
            request.RenewalReminders,
            request.MilestoneAlerts
        });

        user.NotificationPreferences = preferencesJson;

        var result = await _userManager.UpdateAsync(user).ConfigureAwait(false);
        return result.Succeeded;

    }

    public async Task<UserProfileDto?> UpdateProfileAsync(string userId, UpdateProfileRequest request, CancellationToken ct = default)
    {
        // Business rule validation
        if (string.IsNullOrWhiteSpace(request.FullName)
            || request.FullName.Length < 2
            || request.FullName.Length > 100)
        {
            throw new ArgumentException("Full name must be between 2 and 100 characters.", nameof(request));
        }

        if (string.IsNullOrWhiteSpace(request.CurrencyCode)
            || request.CurrencyCode.Length != 3)
        {
            throw new ArgumentException("Currency code must be a 3-character ISO 4217 code.", nameof(request));
        }

        var user = await _userManager.FindByIdAsync(userId).ConfigureAwait(false);
        if (user is null) return null;

        user.FirstName = request.FullName.Split(' ').FirstOrDefault() ?? string.Empty;
        user.LastName = request.FullName.Split(' ').Skip(1).FirstOrDefault() ?? string.Empty;
        user.CurrencyCode = request.CurrencyCode.ToUpperInvariant();

        var result = await _userManager.UpdateAsync(user).ConfigureAwait(false);
        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to update user profile: {errors}");
        }

        return MapToDto(user);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static UserProfileDto MapToDto(User user)
    {
        return new UserProfileDto(
            UserId: user.Id,
            Email: user.Email ?? string.Empty,
            FullName: $"{user.LastName} {user.FirstName}".Trim(),
            Avatar: user.Avatar,
            CurrencyCode: user.CurrencyCode ?? "USD",
            NotificationPreferences: DeserializeNotificationPreferences(user.NotificationPreferences)
        );
    }

    private static NotificationPreferencesDto DeserializeNotificationPreferences(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return new NotificationPreferencesDto(false, false, false);

        try
        {
            var prefs = JsonConvert.DeserializeObject<NotificationPreferencesDto>(json);
            return prefs ?? new NotificationPreferencesDto(false, false, false);
        }
        catch (JsonException)
        {
            // Corrupted data: return safe defaults rather than crashing
            return new NotificationPreferencesDto(false, false, false);
        }
    }

    private static string? DetectMimeType(byte[] header, int bytesRead)
    {
        if (bytesRead >= 3
            && header[0] == JpegMagicBytes[0]
            && header[1] == JpegMagicBytes[1]
            && header[2] == JpegMagicBytes[2])
        {
            return "image/jpeg";
        }

        if (bytesRead >= 8
            && header[0] == PngMagicBytes[0]
            && header[1] == PngMagicBytes[1]
            && header[2] == PngMagicBytes[2]
            && header[3] == PngMagicBytes[3]
            && header[4] == PngMagicBytes[4]
            && header[5] == PngMagicBytes[5]
            && header[6] == PngMagicBytes[6]
            && header[7] == PngMagicBytes[7])
        {
            return "image/png";
        }

        return null;
    }
}
