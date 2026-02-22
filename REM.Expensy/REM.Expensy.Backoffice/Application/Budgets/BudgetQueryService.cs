using Microsoft.EntityFrameworkCore;
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
}
