namespace REM.Expensy.Backoffice.Application.SavingsGoals;

/// <summary>
/// Evaluates milestone completion after funds are added to a savings goal.
/// Must be called within an active database transaction — does not call SaveChangesAsync.
/// </summary>
public interface IMilestoneProgressionService
{
    /// <summary>
    /// Loads all milestones for the given goal and transitions their statuses based on
    /// the goal's current amount. Creates notifications for newly completed milestones.
    /// </summary>
    /// <param name="goalId">The savings goal to evaluate.</param>
    /// <param name="userId">Used to scope the notification to the correct user.</param>
    /// <param name="ct">Cancellation token.</param>
    Task EvaluateAsync(Guid goalId, string userId, CancellationToken ct = default);
}
