using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Notifications;

/// <summary>
/// Handles read and mark-as-read operations for notifications, scoped to the requesting user.
/// </summary>
public class NotificationService(IContext context) : INotificationService
{
    private readonly IContext _context = context;

    /// <inheritdoc/>
    public async Task<NotificationPagedResult> GetAllForUserAsync(string userId, int page = 1, int pageSize = 20, CancellationToken ct = default)
    {
        // Clamp inputs — never trust caller-supplied pagination values.
        // A malicious or buggy client could send page=0 or pageSize=999999.
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        // Build the base query — reused in both Count and List tasks below.
        // The global soft-delete filter is applied automatically.
        var baseQuery = _context.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == userId);

        // --- Run two queries in PARALLEL via Task.WhenAll ---
        //
        // Why parallel?
        // Running them sequentially: CountAsync waits for DB → then ToListAsync waits for DB.
        //   Total time ≈ latency_1 + latency_2
        // Running them in parallel: both are dispatched to the DB at the same time.
        //   Total time ≈ max(latency_1, latency_2)
        //
        // On a connection-pooled API this halves the time spent waiting for the database
        // on every notification list request.
        //
        // IMPORTANT: Both queries must use the SAME CancellationToken. If the HTTP request
        // is cancelled, both database operations are cancelled together.

        var unreadCountTask = baseQuery
            .CountAsync(n => !n.IsRead, ct);     // count of unread (for badge)

        var totalCountTask = baseQuery
            .CountAsync(ct);                      // total (for pagination UI)

        var itemsTask = baseQuery
        .Include(n => n.Type)
        .OrderByDescending(n => n.Created)   // newest first
        .Skip((page - 1) * pageSize)         // skip records before this page
        .Take(pageSize)                       // take only this page's records
        .Select(n => new NotificationDto(
            n.Id,
            n.Title,
            n.Body,
            n.Type.Name,
            n.RelatedId,
            n.IsRead,
            n.Created))
        .ToListAsync(ct);

        // Fire all three queries simultaneously and wait for all to complete.
        await Task.WhenAll(unreadCountTask, totalCountTask, itemsTask).ConfigureAwait(false);

        // At this point all tasks are completed. Accessing .Result is safe — no blocking.
        return new NotificationPagedResult(
            UnreadCount: unreadCountTask.Result,
            Items: itemsTask.Result,
            TotalCount: totalCountTask.Result,
            Page: page,
            PageSize: pageSize);
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
        // Generates a single SQL statement like:
        //   UPDATE "Notifications" SET "IsRead" = TRUE
        //   WHERE "UserId" = @userId AND "IsRead" = FALSE
        //
        // No entities are loaded into memory.
        // No change tracking is involved.
        // The global soft-delete query filter still applies to the WHERE clause.
        await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(
                setter => setter.SetProperty(n => n.IsRead, true),
                ct
            )
            .ConfigureAwait(false);

        // Note: no SaveChangesAsync needed. ExecuteUpdateAsync executes immediately
        // against the database — it bypasses EF's unit-of-work / change tracker entirely.
        // This is intentional and is why it is so efficient.
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default)
    {
        // Load with tracking so EF generates an UPDATE (not a DELETE).
        // The global soft-delete filter excludes already-deleted records automatically.
        var notification = await _context.Notifications
            .Where(n => n.Id == id && n.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (notification is null)
            return false;

        // Soft delete — sets IsDeleted = true. The global query filter will exclude
        // this record from all future queries automatically.
        notification.IsDeleted = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }
}
