using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Notifications;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// Read and mark-as-read endpoints for user notifications.
/// Notifications are system-generated; no creation endpoint is exposed here.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<NotificationsController> _logger;

    public NotificationsController(
        INotificationService notificationService,
        ICurrentUserService currentUserService,
        ILogger<NotificationsController> logger)
    {
        _notificationService = notificationService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Returns all notifications for the current user, ordered newest first.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(NotificationPagedResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<NotificationPagedResult>> GetAll(
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20,
    CancellationToken cancellationToken = default)
    {
        _logger.LogDebug(
            "Getting notifications page {Page} (size {PageSize}) for user {UserId}",
            page, pageSize, _currentUserService.UserId);

        var result = await _notificationService
            .GetAllForUserAsync(_currentUserService.UserId, page, pageSize, cancellationToken)
            .ConfigureAwait(false);

        return Ok(result);
    }

    /// <summary>
    /// Returns the count of unread notifications for the current user.
    /// </summary>
    [HttpGet("unread-count")]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult> GetUnreadCount(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting unread notification count for user {UserId}", _currentUserService.UserId);

        var count = await _notificationService
            .GetUnreadCountAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(new { count });
    }

    /// <summary>
    /// Marks a single notification as read.
    /// </summary>
    [HttpPatch("{id:guid}/read")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkAsRead(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Marking notification {NotificationId} as read for user {UserId}", id, _currentUserService.UserId);

        try
        {
            await _notificationService
                .MarkAsReadAsync(id, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Failed to mark notification {NotificationId} as read for user {UserId}", id, _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    /// <summary>
    /// Marks all unread notifications as read for the current user.
    /// </summary>
    [HttpPatch("read-all")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkAllAsRead(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Marking all notifications as read for user {UserId}", _currentUserService.UserId);

        await _notificationService
            .MarkAllAsReadAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return NoContent();
    }

    /// <summary>
    /// Soft-deletes a notification. Idempotent — returns 404 if not found.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug(
            "Deleting notification {NotificationId} for user {UserId}",
            id, _currentUserService.UserId);

        var deleted = await _notificationService
            .DeleteAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}
