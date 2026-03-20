namespace REM.Expensy.Backoffice.Application.Notifications;

/// <summary>
/// Read and mark-as-read service for user notifications.
/// Notifications are system-generated; there is no creation endpoint.
/// </summary>
public interface INotificationService
{
    /// <summary>
    /// Returns a paginated list of notifications for the user, newest first.
    /// Always includes the total unread count regardless of current page.
    /// </summary>
    Task<NotificationPagedResult> GetAllForUserAsync(string userId, int page = 1, int pageSize = 20, CancellationToken ct = default);

    /// <summary>
    /// Returns the count of unread notifications for the specified user.
    /// </summary>
    Task<int> GetUnreadCountAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Marks a single notification as read. No-op if already read.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when the notification is not found or not owned by the user.</exception>
    Task MarkAsReadAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Marks all unread notifications for the user as read in a single bulk update.
    /// </summary>
    Task MarkAllAsReadAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Soft-deletes a notification. Returns false if not found or not owned by the user.
    /// </summary>
    Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default);
}
