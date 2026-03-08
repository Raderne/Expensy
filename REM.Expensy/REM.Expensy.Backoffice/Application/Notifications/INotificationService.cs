namespace REM.Expensy.Backoffice.Application.Notifications;

/// <summary>
/// Read and mark-as-read service for user notifications.
/// Notifications are system-generated; there is no creation endpoint.
/// </summary>
public interface INotificationService
{
    /// <summary>
    /// Returns all notifications for the specified user, ordered newest first.
    /// </summary>
    Task<IReadOnlyList<NotificationDto>> GetAllForUserAsync(string userId, CancellationToken ct = default);

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
}
