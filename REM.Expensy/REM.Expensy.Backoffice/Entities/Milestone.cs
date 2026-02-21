using REM.Expensy.Backoffice.Entities.Common;
using REM.Expensy.Backoffice.Enums;

namespace REM.Expensy.Backoffice.Entities;

public class Milestone : BaseEntity
{
    public Guid GoalId { get; set; }
    public string Name { get; set; } = null!; // Milestone label (e.g., "Kickoff! First $500 saved")
    public string TargetAmount { get; set; } = null!; // Target amount for this milestone (e.g., "$500")
    public DateOnly TargetDate { get; set; } // Optional target date for the milestone
    public Guid StatusId { get; set; } // Reference to MilestoneStatus (e.g., "Achieved", "Pending", "Missed")
    public DateTime? AchievedAt { get; set; } // Timestamp when the milestone was achieved

    public SavingsGoal Goal { get; set; }
    public MilestoneStatus Status { get; set; }

}

public class MilestoneStatus : BaseEntity
{
    public string Name { get; set; } = null!;
    public MilestoneStatusEnum Code { get; set; }
}