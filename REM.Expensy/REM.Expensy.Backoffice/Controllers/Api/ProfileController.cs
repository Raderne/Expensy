using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Profile;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

[ApiController]
[Authorize]
[Route("api/profile")]
public class ProfileController : ControllerBase
{
    private readonly IProfileService _profileService;
    private readonly ICurrentUserService _currentUser;

    public ProfileController(IProfileService profileService, ICurrentUserService currentUser)
    {
        _profileService = profileService;
        _currentUser = currentUser;
    }

    // GET api/profile
    [HttpGet]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProfile(CancellationToken ct)
    {
        var profile = await _profileService.GetProfileAsync(_currentUser.UserId, ct);
        return profile is null ? NotFound() : Ok(profile);
    }

    // PUT api/profile
    [HttpPut]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateProfile(
        [FromBody] UpdateProfileRequest request,
        CancellationToken ct)
    {
        try
        {
            var profile = await _profileService.UpdateProfileAsync(_currentUser.UserId, request, ct);
            return profile is null ? NotFound() : Ok(profile);
        }
        catch (ArgumentException ex)
        {
            return Problem(
                detail: ex.Message,
                statusCode: StatusCodes.Status400BadRequest,
                title: "Validation Error");
        }
    }

    // PATCH api/profile/notification-preferences
    [HttpPatch("notification-preferences")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateNotificationPreferences(
        [FromBody] UpdateNotificationPreferencesRequest request,
        CancellationToken ct)
    {
        var success = await _profileService.UpdateNotificationPreferencesAsync(_currentUser.UserId, request, ct);
        return success ? NoContent() : NotFound();
    }

    // POST api/profile/avatar
    [HttpPost("avatar")]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateAvatar([FromForm] IFormFile? avatar, CancellationToken ct)
    {
        // Controller-level guard: file must be present
        if (avatar is null || avatar.Length == 0)
            return Problem(
                detail: "No file was uploaded.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Bad Request");

        // Controller-level size pre-check (avoids reading the stream unnecessarily)
        const long maxBytes = 5 * 1024 * 1024;
        if (avatar.Length > maxBytes)
        {
            return Problem(
                detail: "File must not exceed 5 MB.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Bad Request");
        }

        try
        {
            await using var stream = avatar.OpenReadStream();

            var profile = await _profileService.UpdateAvatarAsync(
                userId: _currentUser.UserId,
                fileStream: stream,
                fileName: avatar.FileName,
                contentType: avatar.ContentType,
                fileSize: avatar.Length,
                ct: ct);

            return profile is null ? NotFound() : Ok(profile);
        }
        catch (ArgumentException ex)
        {
            return Problem(
                detail: ex.Message,
                statusCode: StatusCodes.Status400BadRequest,
                title: "Validation Error");
        }
    }
}
