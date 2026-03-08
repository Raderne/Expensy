using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Budgets;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// CRUD endpoints for budgets and budget alerts. All operations are scoped to the authenticated user.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class BudgetsController : ControllerBase
{
    private readonly IBudgetService _budgetService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<BudgetsController> _logger;

    public BudgetsController(
        IBudgetService budgetService,
        ICurrentUserService currentUserService,
        ILogger<BudgetsController> logger)
    {
        _budgetService = budgetService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Returns all budgets owned by the current user.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<BudgetDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<BudgetDto>>> GetAll(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting all budgets for user {UserId}", _currentUserService.UserId);

        var budgets = await _budgetService
            .GetAllForUserAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(budgets);
    }

    /// <summary>
    /// Returns a single budget by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(BudgetDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<BudgetDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting budget {BudgetId} for user {UserId}", id, _currentUserService.UserId);

        var budget = await _budgetService
            .GetByIdAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (budget is null)
            return NotFound();

        return Ok(budget);
    }

    /// <summary>
    /// Creates a new budget for the current user.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(BudgetDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<BudgetDto>> Create([FromBody] CreateBudgetRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Creating budget for user {UserId}", _currentUserService.UserId);

        try
        {
            var budget = await _budgetService
                .CreateAsync(request, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            return CreatedAtAction(nameof(GetById), new { id = budget.Id }, budget);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Business rule violation creating budget for user {UserId}", _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    /// <summary>
    /// Updates the limit, period, and date range of an existing budget.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(BudgetDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<BudgetDto>> Update(Guid id, [FromBody] UpdateBudgetRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Updating budget {BudgetId} for user {UserId}", id, _currentUserService.UserId);

        try
        {
            var budget = await _budgetService
                .UpdateAsync(id, request, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            if (budget is null)
                return NotFound();

            return Ok(budget);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Business rule violation updating budget {BudgetId} for user {UserId}", id, _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    /// <summary>
    /// Soft-deletes a budget.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Deleting budget {BudgetId} for user {UserId}", id, _currentUserService.UserId);

        var deleted = await _budgetService
            .DeleteAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (!deleted)
            return NotFound();

        return NoContent();
    }

    /// <summary>
    /// Returns all unread budget alerts for the current user, ordered newest first.
    /// </summary>
    [HttpGet("alerts")]
    [ProducesResponseType(typeof(IReadOnlyList<BudgetAlertDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<BudgetAlertDto>>> GetAlerts(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting unread budget alerts for user {UserId}", _currentUserService.UserId);

        var alerts = await _budgetService
            .GetUnreadAlertsForUserAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(alerts);
    }
}
