using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Subscriptions;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// CRUD endpoints for subscriptions. All write operations are scoped to the authenticated user.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<SubscriptionsController> _logger;

    public SubscriptionsController(
        ISubscriptionService subscriptionService,
        ICurrentUserService currentUserService,
        ILogger<SubscriptionsController> logger)
    {
        _subscriptionService = subscriptionService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Returns all subscriptions owned by the current user, ordered by next renewal date.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(SubscriptionSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<SubscriptionSummaryDto>> GetAll(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting all subscriptions for user {UserId}", _currentUserService.UserId);

        var subscriptions = await _subscriptionService
            .GetAllForUserAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(subscriptions);
    }

    /// <summary>
    /// Returns active subscriptions with a renewal date within the next 7 days.
    /// </summary>
    [HttpGet("upcoming")]
    [ProducesResponseType(typeof(IReadOnlyList<SubscriptionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<SubscriptionDto>>> GetUpcoming(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting upcoming subscriptions for user {UserId}", _currentUserService.UserId);

        var upcoming = await _subscriptionService
            .GetUpcomingAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(upcoming);
    }

    /// <summary>
    /// Returns a single subscription by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(SubscriptionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SubscriptionDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting subscription {SubscriptionId} for user {UserId}", id, _currentUserService.UserId);

        var subscription = await _subscriptionService
            .GetByIdAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (subscription is null)
            return NotFound();

        return Ok(subscription);
    }

    /// <summary>
    /// Creates a new subscription for the current user.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(SubscriptionDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<SubscriptionDto>> Create([FromBody] CreateSubscriptionRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Creating subscription for user {UserId}", _currentUserService.UserId);

        var subscription = await _subscriptionService
            .CreateAsync(request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return CreatedAtAction(nameof(GetById), new { id = subscription.Id }, subscription);
    }

    /// <summary>
    /// Updates an existing subscription.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(SubscriptionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SubscriptionDto>> Update(Guid id, [FromBody] UpdateSubscriptionRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Updating subscription {SubscriptionId} for user {UserId}", id, _currentUserService.UserId);

        var subscription = await _subscriptionService
            .UpdateAsync(id, request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (subscription is null)
            return NotFound();

        return Ok(subscription);
    }

    /// <summary>
    /// Soft-deletes a subscription.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Deleting subscription {SubscriptionId} for user {UserId}", id, _currentUserService.UserId);

        var deleted = await _subscriptionService
            .DeleteAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (!deleted)
            return NotFound();

        return NoContent();
    }

    /// <summary>
    /// Creates a renewal reminder notification for the given subscription.
    /// Idempotent — if an unread reminder already exists, no duplicate is created.
    /// </summary>
    [HttpPost("{id:guid}/remind")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Remind(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Sending reminder for subscription {SubscriptionId} for user {UserId}",
            id, _currentUserService.UserId);

        var found = await _subscriptionService
            .SendReminderAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (!found)
            return NotFound();

        return NoContent();
    }

    /// <summary>
    /// Returns all available subscription billing cycles. This is lookup data and does not require authentication.
    /// </summary>
    [HttpGet("cycles")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(IReadOnlyList<SubscriptionCycleDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<SubscriptionCycleDto>>> GetCycles(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting subscription cycles");

        var cycles = await _subscriptionService
            .GetCyclesAsync(cancellationToken)
            .ConfigureAwait(false);

        return Ok(cycles);
    }
}
