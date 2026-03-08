using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.SavingsGoals;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// CRUD endpoints for savings goals and milestones. All operations are scoped to the authenticated user.
/// </summary>
[ApiController]
[Route("api/savings-goals")]
[Produces("application/json")]
[Authorize]
public class SavingsGoalsController : ControllerBase
{
    private readonly ISavingsGoalService _savingsGoalService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<SavingsGoalsController> _logger;

    public SavingsGoalsController(
        ISavingsGoalService savingsGoalService,
        ICurrentUserService currentUserService,
        ILogger<SavingsGoalsController> logger)
    {
        _savingsGoalService = savingsGoalService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Returns all savings goals owned by the current user.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<SavingsGoalDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<SavingsGoalDto>>> GetAll(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting all savings goals for user {UserId}", _currentUserService.UserId);

        var goals = await _savingsGoalService
            .GetAllForUserAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(goals);
    }

    /// <summary>
    /// Returns a single savings goal by ID, including its milestones.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(SavingsGoalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SavingsGoalDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting savings goal {GoalId} for user {UserId}", id, _currentUserService.UserId);

        var goal = await _savingsGoalService
            .GetByIdAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (goal is null)
            return NotFound();

        return Ok(goal);
    }

    /// <summary>
    /// Creates a new savings goal for the current user.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(SavingsGoalDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<SavingsGoalDto>> Create([FromBody] CreateSavingsGoalRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Creating savings goal for user {UserId}", _currentUserService.UserId);

        var goal = await _savingsGoalService
            .CreateAsync(request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return CreatedAtAction(nameof(GetById), new { id = goal.Id }, goal);
    }

    /// <summary>
    /// Updates the metadata of an existing savings goal.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(SavingsGoalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SavingsGoalDto>> Update(Guid id, [FromBody] UpdateSavingsGoalRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Updating savings goal {GoalId} for user {UserId}", id, _currentUserService.UserId);

        var goal = await _savingsGoalService
            .UpdateAsync(id, request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (goal is null)
            return NotFound();

        return Ok(goal);
    }

    /// <summary>
    /// Soft-deletes a savings goal.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Deleting savings goal {GoalId} for user {UserId}", id, _currentUserService.UserId);

        var deleted = await _savingsGoalService
            .DeleteAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (!deleted)
            return NotFound();

        return NoContent();
    }

    /// <summary>
    /// Adds funds to an existing savings goal, incrementing its current amount.
    /// </summary>
    [HttpPost("{id:guid}/funds")]
    [ProducesResponseType(typeof(SavingsGoalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SavingsGoalDto>> AddFunds(Guid id, [FromBody] AddFundsRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Adding funds to savings goal {GoalId} for user {UserId}", id, _currentUserService.UserId);

        try
        {
            var goal = await _savingsGoalService
                .AddFundsAsync(id, request, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            if (goal is null)
                return NotFound();

            return Ok(goal);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Business rule violation adding funds to goal {GoalId} for user {UserId}", id, _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    /// <summary>
    /// Adds a milestone to an existing savings goal.
    /// </summary>
    [HttpPost("{id:guid}/milestones")]
    [ProducesResponseType(typeof(MilestoneDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<MilestoneDto>> AddMilestone(Guid id, [FromBody] CreateMilestoneRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Adding milestone to savings goal {GoalId} for user {UserId}", id, _currentUserService.UserId);

        try
        {
            var milestone = await _savingsGoalService
                .AddMilestoneAsync(id, request, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            if (milestone is null)
                return NotFound();

            return CreatedAtAction(nameof(GetById), new { id }, milestone);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Business rule violation adding milestone to goal {GoalId} for user {UserId}", id, _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }
}
