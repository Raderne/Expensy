using REM.Expensy.Backoffice.Entities.Common;
using REM.Expensy.Backoffice.Enums;

namespace REM.Expensy.Backoffice.Entities;

public class Notification : BaseEntity
{
    public Guid UserId { get; set; } // Target user
    public string Type { get; set; } // budget_alert, renewal_reminder, milestone_reached
    public string Title { get; set; } // Short notification heading
    public string Body { get; set; } // Detailed message
    public Guid? RelatedId { get; set; }  // Reference to the related entity(budget, subscription, goal)
    public bool IsRead { get; set; } // Read status
}

public class NotificationType : BaseEntity
{
    public string Name { get; set; } // e.g., "Budget Alert", "Renewal Reminder", "Milestone Reached"
    public NotificationTypeEnum Code { get; set; } // e.g., BudgetAlert = 1, RenewalReminder = 2, MilestoneReached = 3
}
