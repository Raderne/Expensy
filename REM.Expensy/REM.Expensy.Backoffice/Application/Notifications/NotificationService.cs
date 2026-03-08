using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Notifications;

/// <summary>
/// Handles read and mark-as-read operations for notifications, scoped to the requesting user.
/// </summary>
public class NotificationService : INotificationService
{
    private readonly IContext _context;

    public NotificationService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<NotificationDto>> GetAllForUserAsync(string userId, CancellationToken ct = default)
    {
        var notifications = await _context.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == userId)
            .Include(n => n.Type)
            .OrderByDescending(n => n.Created)
            .Select(n => new NotificationDto(
                n.Id,
                n.Title,
                n.Body,
                n.Type.Name,
                n.RelatedId,
                n.IsRead,
                n.Created))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return notifications;
    }

    /// <inheritdoc/>
    public async Task<int> GetUnreadCountAsync(string userId, CancellationToken ct = default)
    {
        var count = await _context.Notifications
            .AsNoTracking()
            .CountAsync(n => n.UserId == userId && !n.IsRead, ct)
            .ConfigureAwait(false);

        return count;
    }

    /// <inheritdoc/>
    public async Task MarkAsReadAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var notification = await _context.Notifications
            .Where(n => n.Id == id && n.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException($"Notification {id} was not found or does not belong to the current user.");

        if (notification.IsRead)
            return;

        notification.IsRead = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task MarkAllAsReadAsync(string userId, CancellationToken ct = default)
    {
        var unread = await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync(ct)
            .ConfigureAwait(false);

        if (unread.Count == 0)
            return;

        foreach (var notification in unread)
            notification.IsRead = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);
    }
}
