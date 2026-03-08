namespace REM.Expensy.Backoffice.Application.SavingsGoals;

/// <summary>
/// Read model for a single milestone within a savings goal.
/// </summary>
public record MilestoneDto(
    Guid Id,
    string Name,
    decimal TargetAmount,
    DateOnly TargetDate,
    string StatusName,
    DateTime? AchievedAt);

/// <summary>
/// Read model returned from savings goal queries.
/// </summary>
public record SavingsGoalDto(
    Guid Id,
    string Name,
    string? Icon,
    string? Color,
    decimal TargetAmount,
    decimal CurrentAmount,
    decimal Progress,
    decimal MonthlyContribution,
    DateOnly TargetDate,
    IReadOnlyList<MilestoneDto> Milestones);

/// <summary>
/// Payload for creating a new savings goal.
/// </summary>
public record CreateSavingsGoalRequest(
    string Name,
    decimal TargetAmount,
    DateOnly TargetDate,
    string? Icon,
    string? Color);

/// <summary>
/// Payload for updating an existing savings goal's metadata.
/// </summary>
public record UpdateSavingsGoalRequest(
    string Name,
    decimal TargetAmount,
    DateOnly TargetDate,
    string? Icon,
    string? Color);

/// <summary>
/// Payload for adding funds to a savings goal.
/// </summary>
public record AddFundsRequest(decimal Amount);

/// <summary>
/// Payload for adding a milestone to an existing savings goal.
/// </summary>
public record CreateMilestoneRequest(
    string Name,
    decimal TargetAmount,
    DateOnly TargetDate);
