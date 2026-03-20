using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Enums;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Subscriptions;

/// <summary>
/// Handles CRUD operations for subscriptions, scoped to the requesting user.
/// </summary>
public class SubscriptionService : ISubscriptionService
{
    private readonly IContext _context;

    public SubscriptionService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<SubscriptionSummaryDto> GetAllForUserAsync(string userId, CancellationToken ct = default)
    {
        var subscriptions = await _context.Subscriptions
            .AsNoTracking()
            .Where(s => s.UserId == userId)
            .Include(s => s.Cycle)
            .Include(s => s.Category)
            .OrderBy(s => s.NextRenewal)
            .Select(s => new SubscriptionDto(
                s.Id,
                s.Name,
                s.Icon,
                s.Amount,
                s.Cycle.Name,
                s.NextRenewal,
                s.IsActive,
                s.CategoryId,
                s.Category.Name))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        // --- Monthly normalization ---
        // Only include ACTIVE subscriptions in the spend total.
        // A paused subscription is not costing money right now.
        var totalMonthlySpend = subscriptions
            .Where(s => s.IsActive)
            .Sum(s => NormalizeToMonthly(s.CycleName, s.Amount));

        return new SubscriptionSummaryDto(totalMonthlySpend, subscriptions);
    }

    /// <inheritdoc/>
    public async Task<SubscriptionDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var subscription = await _context.Subscriptions
            .AsNoTracking()
            .Where(s => s.Id == id && s.UserId == userId)
            .Include(s => s.Cycle)
            .Include(s => s.Category)
            .Select(s => new SubscriptionDto(
                s.Id,
                s.Name,
                s.Icon,
                s.Amount,
                s.Cycle.Name,
                s.NextRenewal,
                s.IsActive,
                s.CategoryId,
                s.Category.Name))
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        return subscription;
    }

    /// <inheritdoc/>
    public async Task<SubscriptionDto> CreateAsync(CreateSubscriptionRequest request, string userId, CancellationToken ct = default)
    {
        var subscription = new Subscription
        {
            UserId = userId,
            Name = request.Name,
            Icon = request.Icon,
            Amount = request.Amount,
            CycleId = request.CycleId,
            NextRenewal = request.NextRenewal,
            IsActive = request.IsActive,
            CategoryId = request.CategoryId
        };

        await _context.Subscriptions.AddAsync(subscription, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return (await GetByIdAsync(subscription.Id, userId, ct).ConfigureAwait(false))!;
    }

    /// <inheritdoc/>
    public async Task<SubscriptionDto?> UpdateAsync(Guid id, UpdateSubscriptionRequest request, string userId, CancellationToken ct = default)
    {
        var subscription = await _context.Subscriptions
            .Where(s => s.Id == id && s.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (subscription is null)
            return null;

        subscription.Name = request.Name;
        subscription.Icon = request.Icon;
        subscription.Amount = request.Amount;
        subscription.CycleId = request.CycleId;
        subscription.NextRenewal = request.NextRenewal;
        subscription.IsActive = request.IsActive;
        subscription.CategoryId = request.CategoryId;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return await GetByIdAsync(id, userId, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var subscription = await _context.Subscriptions
            .Where(s => s.Id == id && s.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (subscription is null)
            return false;

        subscription.IsDeleted = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<SubscriptionCycleDto>> GetCyclesAsync(CancellationToken ct = default)
    {
        var cycles = await _context.SubscriptionCycles
            .AsNoTracking()
            .OrderBy(c => c.Name)
            .Select(c => new SubscriptionCycleDto(c.Id, c.Name))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return cycles;
    }

    public async Task<IReadOnlyList<SubscriptionDto>> GetUpcomingAsync(string userId, CancellationToken ct = default)
    {
        // Calculate the cutoff date — 7 days from today.
        // IMPORTANT: use DateTime.UtcNow, not DateTime.Now.
        // The server may be running in any timezone. UtcNow is timezone-independent.
        // DateOnly.FromDateTime strips the time component for a clean date comparison.
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var cutoff = today.AddDays(7);

        var upcoming = await _context.Subscriptions
            .AsNoTracking()
            .Where(s => s.UserId == userId &&
                        s.IsActive &&
                        s.NextRenewal >= today &&
                        s.NextRenewal <= cutoff)
            .Include(s => s.Cycle)
            .Include(s => s.Category)
            .OrderBy(s => s.NextRenewal)       // soonest renewal first
            .Select(s => new SubscriptionDto(
                s.Id,
                s.Name,
                s.Icon,
                s.Amount,
                s.Cycle.Name,
                s.NextRenewal,
                s.IsActive,
                s.CategoryId,
                s.Category.Name))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return upcoming;
    }

    public async Task<bool> SendReminderAsync(Guid subscriptionId, string userId, CancellationToken ct = default)
    {
        // Verify the subscription exists and belongs to this user.
        // Use AsNoTracking + Select to fetch only what we need — we do not need
        // the full entity graph to do the ownership check.
        var subscription = await _context.Subscriptions
            .AsNoTracking()
            .Where(s => s.Id == subscriptionId && s.UserId == userId)
            .Select(s => new { s.Id, s.Name, s.NextRenewal })
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (subscription is null)
            return false;   // 404 — subscription not found or not owned by this user

        // Load the RenewalReminder notification type.
        var reminderType = await _context.NotificationTypes
            .AsNoTracking()
            .Where(t => t.Code == NotificationTypeEnum.RenewalReminder)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException(
                "NotificationType 'RenewalReminder' is not seeded. Run the SeedReferenceData migration.");

        // Idempotency check: do not create a duplicate reminder if one already exists unread
        // for this subscription. RelatedId links the notification to the subscription entity.
        var existingReminder = await _context.Notifications
            .AsNoTracking()
            .AnyAsync(n =>
                n.UserId == userId &&
                n.TypeId == reminderType.Id &&
                n.RelatedId == subscriptionId &&
                !n.IsRead,                          // only block if the existing one is still unread
                ct)
            .ConfigureAwait(false);

        if (existingReminder)
        {
            // A reminder is already sitting in the user's inbox. Do nothing.
            // We still return true — from the caller's perspective the operation succeeded;
            // it's just a no-op. The controller will return 204 either way.
            return true;
        }

        // Create the notification.
        var notification = new Notification
        {
            UserId = userId,
            TypeId = reminderType.Id,
            Title = "Subscription Renewal Reminder",
            Body = $"'{subscription.Name}' renews on {subscription.NextRenewal:MMMM d, yyyy}. Make sure you have funds ready.",
            RelatedId = subscriptionId,
            IsRead = false
        };

        await _context.Notifications.AddAsync(notification, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }

    #region Private helpers

    /// <summary>
    /// Converts a subscription amount to its monthly equivalent.
    /// </summary>
    /// <param name="cycleName">The display name of the billing cycle (e.g., "Monthly", "Yearly").</param>
    /// <param name="amount">The cost per billing cycle.</param>
    private static decimal NormalizeToMonthly(string cycleName, decimal amount) =>
        // We match on the display name here because that is what the DTO exposes.
        // An alternative approach is to include PeriodEnum Code in the DTO and match on that instead.
        // Either works — just be consistent.
        cycleName.ToLowerInvariant() switch
        {
            "daily" => amount * 30m,
            "weekly" => amount * (decimal)(52.0 / 12.0),   // ~4.333 weeks/month
            "monthly" => amount,
            "yearly" => amount / 12m,
            _ => amount   // unknown cycle: pass through unchanged rather than throwing
        };

    #endregion Private helpers
}
