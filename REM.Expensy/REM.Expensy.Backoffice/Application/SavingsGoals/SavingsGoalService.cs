using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Enums;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.SavingsGoals;

/// <summary>
/// Handles CRUD operations for savings goals and milestones, scoped to the requesting user.
/// </summary>
public class SavingsGoalService(IContext context, IMilestoneProgressionService milestoneProgressionService) : ISavingsGoalService
{
    private readonly IContext _context = context;
    private readonly IMilestoneProgressionService _milestoneProgressionService = milestoneProgressionService;

    /// <inheritdoc/>
    public async Task<IReadOnlyList<SavingsGoalDto>> GetAllForUserAsync(string userId, CancellationToken ct = default)
    {
        var goals = await _context.SavingsGoals
            .AsNoTracking()
            .Where(g => g.UserId == userId)
            .Include(g => g.User)
            .OrderBy(g => g.TargetDate)
            .ToListAsync(ct)
            .ConfigureAwait(false);

        // Load milestones separately to avoid EF cartesian product on Include
        var goalIds = goals.Select(g => g.Id).ToList();
        var milestones = await _context.Milestones
            .AsNoTracking()
            .Where(m => goalIds.Contains(m.GoalId))
            .Include(m => m.Status)
            .ToListAsync(ct)
            .ConfigureAwait(false);

        var milestonesByGoal = milestones
            .GroupBy(m => m.GoalId)
            .ToDictionary(g => g.Key, g => g.ToList());

        return goals.Select(g => MapToDto(g, milestonesByGoal.GetValueOrDefault(g.Id) ?? [])).ToList();
    }

    /// <inheritdoc/>
    public async Task<SavingsGoalDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var goal = await _context.SavingsGoals
            .AsNoTracking()
            .Where(g => g.Id == id && g.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (goal is null)
            return null;

        var milestones = await _context.Milestones
            .AsNoTracking()
            .Where(m => m.GoalId == id)
            .Include(m => m.Status)
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return MapToDto(goal, milestones);
    }

    /// <inheritdoc/>
    public async Task<SavingsGoalDto> CreateAsync(CreateSavingsGoalRequest request, string userId, CancellationToken ct = default)
    {
        var goal = new SavingsGoal
        {
            UserId = userId,
            Name = request.Name,
            TargetAmount = request.TargetAmount,
            CurrentAmount = 0,
            TargetDate = request.TargetDate,
            Icon = request.Icon,
            Color = request.Color
        };

        await _context.SavingsGoals.AddAsync(goal, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return MapToDto(goal, []);
    }

    /// <inheritdoc/>
    public async Task<SavingsGoalDto?> UpdateAsync(Guid id, UpdateSavingsGoalRequest request, string userId, CancellationToken ct = default)
    {
        var goal = await _context.SavingsGoals
            .Where(g => g.Id == id && g.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (goal is null)
            return null;

        goal.Name = request.Name;
        goal.TargetAmount = request.TargetAmount;
        goal.TargetDate = request.TargetDate;
        goal.Icon = request.Icon;
        goal.Color = request.Color;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return await GetByIdAsync(id, userId, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var goal = await _context.SavingsGoals
            .Where(g => g.Id == id && g.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (goal is null)
            return false;

        goal.IsDeleted = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }

    /// <inheritdoc/>
    public async Task<SavingsGoalDto?> AddFundsAsync(Guid id, AddFundsRequest request, string userId, CancellationToken ct = default)
    {
        // Load the goal — tracked (no AsNoTracking) because we will modify CurrentAmount.
        var goal = await _context.SavingsGoals
            .Where(g => g.Id == id && g.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (goal is null)
            return null;

        // CAP LOGIC (changed from the original throw):
        // If the user tries to deposit more than the remaining balance, we accept the deposit
        // but only credit up to the target. This is friendlier than rejecting the request.
        // Example: goal target = $1000, current = $800, user deposits $300.
        //   effectiveAmount = Min(300, 1000 - 800) = Min(300, 200) = $200.
        //   The goal reaches exactly $1000, not $1100.
        var effectiveAmount = Math.Min(request.Amount, goal.TargetAmount - goal.CurrentAmount);

        // If the goal is already full (currentAmount == targetAmount), effectiveAmount will be 0.
        // No-op — return the current state without touching the DB.
        if (effectiveAmount <= 0)
            return await GetByIdAsync(id, userId, ct).ConfigureAwait(false); // Synchronously wait since we're not modifying anything.

        // Open a database transaction.
        // Everything inside must succeed or nothing is committed.
        await _context.BeginTransactionAsync().ConfigureAwait(false);

        try
        {
            // Apply the (possibly capped) deposit.
            goal.CurrentAmount += effectiveAmount;

            // Evaluate milestones — this modifies milestone entities tracked by EF
            // and queues new Notification records. It does NOT call SaveChangesAsync.
            await _milestoneProgressionService
                .EvaluateAsync(id, userId, ct)
                .ConfigureAwait(false);

            // Single SaveChangesAsync commits all of:
            //   - the updated goal.CurrentAmount
            //   - any milestone status changes from EvaluateAsync
            //   - any new Notification rows from EvaluateAsync
            await _context.SaveChangesAsync(ct).ConfigureAwait(false);

            // Commit the transaction. If this throws, EF rolls back automatically
            // because we have not disposed the transaction yet.
            await _context.CommitTransactionAsync(ct).ConfigureAwait(false);
        }
        catch
        {
            // Something went wrong after BeginTransactionAsync.
            // Roll back so we do not persist a half-updated goal.
            _context.RollbackTransaction();
            throw; // re-throw so the controller can log and return 500
        }

        // Re-query with all navigation properties populated for the response DTO.
        return await GetByIdAsync(id, userId, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<MilestoneDto?> AddMilestoneAsync(Guid goalId, CreateMilestoneRequest request, string userId, CancellationToken ct = default)
    {
        // Verify the goal exists and is owned by the user
        var goalExists = await _context.SavingsGoals
            .AsNoTracking()
            .AnyAsync(g => g.Id == goalId && g.UserId == userId, ct)
            .ConfigureAwait(false);

        if (!goalExists)
            return null;

        var pendingStatus = await _context.MilestoneStatuses
            .AsNoTracking()
            .Where(s => s.Code == MilestoneStatusEnum.NotStarted)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Milestone status 'NotStarted' is not seeded. Contact an administrator.");

        var milestone = new Milestone
        {
            GoalId = goalId,
            Name = request.Name,
            TargetAmount = request.TargetAmount,
            TargetDate = request.TargetDate,
            StatusId = pendingStatus.Id,
            AchievedAt = null
        };

        await _context.Milestones.AddAsync(milestone, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return new MilestoneDto(
            milestone.Id,
            milestone.Name,
            milestone.TargetAmount,
            milestone.TargetDate,
            pendingStatus.Name,
            milestone.AchievedAt);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private static SavingsGoalDto MapToDto(SavingsGoal goal, IList<Milestone> milestones)
    {
        var milestoneDtos = milestones
            .OrderBy(m => m.TargetDate)
            .Select(m => new MilestoneDto(
                m.Id,
                m.Name,
                m.TargetAmount,
                m.TargetDate,
                m.Status?.Name ?? string.Empty,
                m.AchievedAt))
            .ToList();

        return new SavingsGoalDto(
            goal.Id,
            goal.Name,
            goal.Icon,
            goal.Color,
            goal.TargetAmount,
            goal.CurrentAmount,
            goal.Progress,
            goal.MonthlyContribution,
            goal.TargetDate,
            milestoneDtos);
    }
}
