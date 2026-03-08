using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
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
    public async Task<IReadOnlyList<SubscriptionDto>> GetAllForUserAsync(string userId, CancellationToken ct = default)
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

        return subscriptions;
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
}
