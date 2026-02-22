namespace REM.Expensy.Backoffice.Application.Budgets;

/// <summary>
/// API response DTO for a budget (read model).
/// </summary>
public record BudgetDto
{
    public Guid Id { get; init; }
    public Guid UserId { get; init; }
    public Guid CategoryId { get; init; }
    public string CategoryName { get; init; } = string.Empty;
    public decimal Limit { get; init; }
    public decimal Spent { get; init; }
    public string Period { get; init; } = string.Empty;
    public Guid StatusId { get; init; }
    public string StatusTitle { get; init; } = string.Empty;
    public DateOnly StartDate { get; init; }
    public DateOnly EndDate { get; init; }
}
