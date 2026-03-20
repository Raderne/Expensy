using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Enums;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.SavingsGoals;

/// <summary>
/// Evaluates milestone completion after funds are added to a savings goal.
/// Must always be called within an active database transaction owned by the caller.
/// </summary>
public class MilestoneProgressionService(IContext context, ILogger<MilestoneProgressionService> logger) : IMilestoneProgressionService
{
    private readonly IContext _context = context;
    private readonly ILogger<MilestoneProgressionService> _logger = logger;

    /// <inheritdoc/>
    public async Task EvaluateAsync(Guid goalId, string userId, CancellationToken ct = default)
    {
        // Load the goal — we need CurrentAmount to compare against each milestone target.
        // We use AsNoTracking here because we are NOT modifying the goal in this method;
        // the goal is already being tracked by the caller (AddFundsAsync).
        var goal = await _context.SavingsGoals
            .AsNoTracking()
            .Where(g => g.Id == goalId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (goal is null)
        {
            // This should never happen — the caller already verified the goal exists.
            // Log and bail gracefully rather than throwing inside a transaction.
            _logger.LogWarning("MilestoneProgressionService: goal {GoalId} not found. Skipping evaluation.", goalId);
            return;
        }

        // Load milestones in ascending TargetAmount order.
        // CRITICAL: the order drives the entire algorithm.
        // A milestone at $500 must be evaluated before the one at $1000.
        var milestones = await _context.Milestones
            .Where(m => m.GoalId == goalId)
            .OrderBy(m => m.TargetAmount)
            .ToListAsync()
            .ConfigureAwait(false);


        if (milestones.Count == 0)
        {
            // Nothing to evaluate — goal has no milestones.
            return;
        }

        // Load the status lookup table once.
        // These rows were seeded in Phase 0 (MilestoneStatuses seed).
        // We load them by their enum code so we are not hard-coding GUIDs.
        var statuses = await _context.MilestoneStatuses
            .AsNoTracking()
            .ToListAsync().ConfigureAwait(false);

        // Helper: find a status ID by its enum code, or throw a clear error.
        // If this throws it means the Phase 0 seed was never run — tell the developer.
        Guid GetStatusId(MilestoneStatusEnum code) =>
            statuses.FirstOrDefault(s => s.Code == code)?.Id
            ?? throw new ArgumentException($"MilestoneStatus '{code}' is not seeded. Run the SeedReferenceData migration.");

        var completedStatusId = GetStatusId(MilestoneStatusEnum.Completed);
        var inProgressStatusId = GetStatusId(MilestoneStatusEnum.InProgress);
        var notStartedStatusId = GetStatusId(MilestoneStatusEnum.NotStarted);

        // Load the notification type for MilestoneReached.
        var milestoneNotificationType = await _context.NotificationTypes
            .AsNoTracking()
            .Where(t => t.Code == NotificationTypeEnum.MilestoneReached)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("NotificationType 'MilestoneReached' is not seeded. Run the SeedReferenceData migration.");

        // --- Phase 1: Mark newly-completed milestones ---
        foreach (var milestone in milestones)
        {
            var alreadyCompleted = milestone.StatusId == completedStatusId;

            // If the user's current savings cover this milestone AND it wasn't already done:
            if (goal.CurrentAmount >= milestone.TargetAmount && !alreadyCompleted)
            {
                _logger.LogInformation(
                    "Goal {GoalId}: milestone '{MilestoneName}' completed at {CurrentAmount:C}.",
                    goalId, milestone.Name, goal.CurrentAmount);

                // Update the milestone status in EF's change tracker.
                // SaveChangesAsync will be called by the caller.
                milestone.StatusId = completedStatusId;
                milestone.AchievedAt = DateTime.UtcNow;

                // Create a notification so the user sees a "Milestone Reached" alert.
                var notification = new Notification
                {
                    UserId = userId,
                    TypeId = milestoneNotificationType.Id,
                    Title = "Milestone Reached!",
                    // Body tells the user exactly which milestone they hit.
                    Body = $"You've reached '{milestone.Name}' on your savings goal!",
                    RelatedId = goalId,   // lets the frontend deep-link to the goal
                    IsRead = false
                };

                // Add to context — will be inserted when SaveChangesAsync is called by caller.
                await _context.Notifications.AddAsync(notification, ct).ConfigureAwait(false);
            }
        }

        // --- Phase 2: Assign InProgress / NotStarted to remaining milestones ---

        // After the completion sweep, find the first milestone that is NOT completed.
        // This is the next target the user is working toward.

        bool inProgressAssigned = false;

        foreach (var milestone in milestones)
        {
            // Skip milestones that were just marked completed (or were already completed).
            if (milestone.StatusId == completedStatusId)
                continue;

            if (!inProgressAssigned)
            {
                // First non-completed milestone becomes InProgress.
                milestone.StatusId = inProgressStatusId;
                inProgressAssigned = true;
            }
            else
            {
                // All subsequent non-completed milestones revert to NotStarted.
                // (They may have been InProgress before — we reset them.)
                milestone.StatusId = notStartedStatusId;
            }
        }

        // NOTE: No SaveChangesAsync here.
        // The caller (AddFundsAsync) will commit everything in a single transaction:
        //   - goal.CurrentAmount update
        //   - milestone status changes (tracked above)
        //   - new Notification entities (added to context above)
    }
}
