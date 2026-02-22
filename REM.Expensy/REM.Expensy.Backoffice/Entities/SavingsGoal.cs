using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Entities;

public class SavingsGoal : BaseEntity
{
    public string UserId { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string? Icon { get; set; }
    public string? Color { get; set; } // Hex color for the goal card
    public decimal TargetAmount { get; set; }
    public decimal CurrentAmount { get; set; }
    public DateOnly TargetDate { get; set; }
    public decimal Progress => TargetAmount == 0 ? 0 : Math.Min(CurrentAmount / TargetAmount, 1) * 100;
    public decimal MonthlyContribution => CalculateMonthlyContribution(); // Suggested monthly contribution to hit the target date

    public User User { get; set; }

    private decimal CalculateMonthlyContribution()
    {
        var monthsRemaining = Math.Max(1, ((TargetDate.Year - DateTime.Now.Year) * 12) + TargetDate.Month - DateTime.Now.Month);
        return (TargetAmount - CurrentAmount) / monthsRemaining;
    }
}