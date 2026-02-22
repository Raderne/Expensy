using REM.Expensy.Backoffice.Entities.Common;
using REM.Expensy.Backoffice.Enums;

namespace REM.Expensy.Backoffice.Entities;

public class Subscription : BaseEntity
{
    public string UserId { get; set; } = null!;
    public string Name { get; set; } = null!; // Subscription name(e.g., "Netflix Premium")
    public string? Icon { get; set; } //  App logo or icon identifier
    public decimal Amount { get; set; } // Cost per billing cycle
    public Guid CycleId { get; set; } // Billing frequency: monthly, yearly
    public DateOnly NextRenewal { get; set; } // Date of the next renewal/charge
    public bool IsActive { get; set; } // Whether the subscription is currently active
    public Guid CategoryId { get; set; } // Associated category(e.g., Entertainment)

    public User User { get; set; }
    public SubscriptionCycle Cycle { get; set; }
    public Category Category { get; set; }
}

public class SubscriptionCycle : BaseEntity
{
    public string Name { get; set; } = null!; // e.g., "Monthly", "Yearly"
    public PeriodEnum Code { get; set; } // e.g., Monthly = 1, Yearly = 2
}