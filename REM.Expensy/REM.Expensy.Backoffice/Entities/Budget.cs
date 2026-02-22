using REM.Expensy.Backoffice.Entities.Common;
using REM.Expensy.Backoffice.Enums;

namespace REM.Expensy.Backoffice.Entities;

public class Budget : BaseEntity
{
    public string UserId { get; set; } = null!;
    public User User { get; set; } = null!;
    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!;
    public decimal Limit { get; set; }
    public decimal Spent { get; set; }
    public PeriodEnum Period { get; set; }
    public Guid StatusId { get; set; }
    public BudgetStatus Status { get; set; } = null!;
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
}

public class BudgetStatus : BaseEntity
{
    public string Title { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public BudgetStatusEnum Code { get; set; }
}