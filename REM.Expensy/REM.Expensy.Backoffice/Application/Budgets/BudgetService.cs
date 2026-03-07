using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Enums;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Budgets;

/// <summary>
/// Handles CRUD operations for budgets, scoped to the requesting user.
/// </summary>
public class BudgetService : IBudgetService
{
    private readonly IContext _context;

    public BudgetService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<BudgetDto>> GetAllForUserAsync(string userId, CancellationToken ct = default)
    {
        var budgets = await _context.Budgets
            .AsNoTracking()
            .Where(b => b.UserId == userId)
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
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return budgets;
    }

    /// <inheritdoc/>
    public async Task<BudgetDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var budget = await _context.Budgets
            .AsNoTracking()
            .Where(b => b.Id == id && b.UserId == userId)
            .Include(b => b.Category)
            .Include(b => b.Status)
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
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        return budget;
    }

    /// <inheritdoc/>
    public async Task<BudgetDto> CreateAsync(CreateBudgetRequest request, string userId, CancellationToken ct = default)
    {
        if (!Enum.TryParse<PeriodEnum>(request.Period, ignoreCase: true, out var period))
            throw new InvalidOperationException($"'{request.Period}' is not a valid period. Valid values: {string.Join(", ", Enum.GetNames<PeriodEnum>())}.");

        var activeStatus = await _context.BudgetStatuses
            .AsNoTracking()
            .Where(s => s.Code == BudgetStatusEnum.OnTrack)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Budget status 'OnTrack' is not seeded. Contact an administrator.");

        var budget = new Budget
        {
            UserId = userId,
            CategoryId = request.CategoryId,
            Limit = request.Limit,
            Spent = 0,
            Period = period,
            StatusId = activeStatus.Id,
            StartDate = request.StartDate,
            EndDate = request.EndDate
        };

        await _context.Budgets.AddAsync(budget, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        // Re-query to return fully populated DTO (category name etc.)
        return (await GetByIdAsync(budget.Id, userId, ct).ConfigureAwait(false))!;
    }

    /// <inheritdoc/>
    public async Task<BudgetDto?> UpdateAsync(Guid id, UpdateBudgetRequest request, string userId, CancellationToken ct = default)
    {
        if (!Enum.TryParse<PeriodEnum>(request.Period, ignoreCase: true, out var period))
            throw new InvalidOperationException($"'{request.Period}' is not a valid period. Valid values: {string.Join(", ", Enum.GetNames<PeriodEnum>())}.");

        var budget = await _context.Budgets
            .Where(b => b.Id == id && b.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (budget is null)
            return null;

        budget.Limit = request.Limit;
        budget.Period = period;
        budget.StartDate = request.StartDate;
        budget.EndDate = request.EndDate;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return await GetByIdAsync(id, userId, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var budget = await _context.Budgets
            .Where(b => b.Id == id && b.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (budget is null)
            return false;

        budget.IsDeleted = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<BudgetAlertDto>> GetUnreadAlertsForUserAsync(string userId, CancellationToken ct = default)
    {
        var alerts = await _context.BudgetsAlerts
            .AsNoTracking()
            .Where(a => a.UserId == userId && !a.IsRead)
            .Include(a => a.Category)
            .OrderByDescending(a => a.Created)
            .Select(a => new BudgetAlertDto(
                a.Id,
                a.BudgetId,
                a.CategoryId,
                a.Category.Name,
                a.OverspentBy,
                a.IsRead,
                a.Created))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return alerts;
    }
}
