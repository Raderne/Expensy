using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Enums;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Budgets;

/// <summary>
/// Implements budget queries using the read-side context (best practice: read through abstraction, return DTOs).
/// </summary>
public class BudgetQueryService : IBudgetQueryService
{
    private readonly IContext _context;

    public BudgetQueryService(IContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyList<BudgetDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var list = await _context.Budgets
            .AsNoTracking()
            .Include(b => b.Category)
            .Include(b => b.Status)
            .OrderBy(b => b.StartDate)
            .Select(b => new BudgetDto
            {
                Id = b.Id,
                UserId = b.UserId,
                CategoryId = b.CategoryId,
                CategoryName = b.Category.Name,
                Limit = b.Limit,
                Spent = b.Spent,
                Period = b.Period.ToString(),
                StatusId = b.StatusId,
                StatusTitle = b.Status.Title,
                StartDate = b.StartDate,
                EndDate = b.EndDate
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return list;
    }

    /// <inheritdoc/>
    public async Task<BudgetSummaryDto> GetSummaryAsync(string userId, CancellationToken cancellationToken = default)
    {
        // Fetch all active budgets for this user with category + status in one query.
        var budgets = await _context.Budgets
            .AsNoTracking()
            .Where(b => b.UserId == userId)
            .Select(b => new
            {
                b.Id,
                b.CategoryId,
                CategoryName  = b.Category.Name,
                CategoryIcon  = b.Category.Icon,
                CategoryColor = b.Category.Color,
                b.Limit,
                b.Spent,
                StatusCode  = b.Status.Code,
                StatusTitle = b.Status.Title
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        // Compute per-budget rows with insight tips — pure C# logic, no DB column.
        var progressRows = budgets.Select(b =>
        {
            var remaining   = b.Limit - b.Spent;
            var pct         = b.Limit == 0 ? 0m : Math.Round(b.Spent / b.Limit * 100, 2);
            var insightTip  = BuildInsightTip(b.CategoryName, pct, remaining);

            return new BudgetProgressDto(
                b.Id,
                b.CategoryId,
                b.CategoryName,
                b.CategoryIcon,
                b.CategoryColor,
                b.Limit,
                b.Spent,
                remaining,
                pct,
                b.StatusCode,
                b.StatusTitle,
                insightTip);
        }).ToList();

        // Aggregate totals across all budgets.
        var totalBudgeted = budgets.Sum(b => b.Limit);
        var totalSpent    = budgets.Sum(b => b.Spent);
        var overallPct    = totalBudgeted == 0
            ? 0m
            : Math.Round(totalSpent / totalBudgeted * 100, 2);

        var overall = new BudgetOverallProgressDto(totalBudgeted, totalSpent, overallPct);

        return new BudgetSummaryDto(overall, progressRows);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /// <summary>
    /// Generates a human-readable insight tip for a budget based on the percentage
    /// of the limit that has been consumed. Computed entirely in the Application
    /// layer — this is business display logic, not data worth persisting.
    /// </summary>
    private static string BuildInsightTip(string categoryName, decimal percentSpent, decimal remaining)
    {
        return percentSpent switch
        {
            < 50m  => $"Great job! You're well within your {categoryName} budget.",
            < 75m  => $"You're halfway through your {categoryName} budget. Keep it up.",
            < 100m => $"Heads up — you've used {percentSpent:0}% of your {categoryName} budget.",
            _      => $"You've exceeded your {categoryName} budget by {Math.Abs(remaining):C}."
        };
    }
}
