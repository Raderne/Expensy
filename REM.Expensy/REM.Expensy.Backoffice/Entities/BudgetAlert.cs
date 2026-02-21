using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Entities;

public class BudgetAlert : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid BudgetId { get; set; }
    public Guid CategoryId { get; set; }
    public decimal OverspentBy { get; set; }
    public bool IsRead { get; set; } = false;

    public User User { get; set; }
    public Budget Budget { get; set; }
    public Category Category { get; set; }
}
