using REM.Expensy.Backoffice.Entities.Common;
using REM.Expensy.Backoffice.Enums;

namespace REM.Expensy.Backoffice.Entities;

public class Notification : BaseEntity
{
    public string UserId { get; set; } = null!; // Target user
    public Guid TypeId { get; set; } // budget_alert, renewal_reminder, milestone_reached
    public string Title { get; set; } = string.Empty; // Short notification heading
    public string Body { get; set; } = string.Empty;  // Detailed message
    public Guid? RelatedId { get; set; }  // Reference to the related entity(budget, subscription, goal)
    public bool IsRead { get; set; } // Read status

    public User User { get; set; } = null!; // Navigation to User
    public NotificationType Type { get; set; } = null!; // Navigation to NotificationType
}

public class NotificationType : BaseEntity
{
    public string Name { get; set; } = string.Empty; // e.g., "Budget Alert", "Renewal Reminder", "Milestone Reached"
    public NotificationTypeEnum Code { get; set; } // e.g., BudgetAlert = 1, RenewalReminder = 2, MilestoneReached = 3
}
