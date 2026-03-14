using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Analytics;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// Spending analytics endpoints for the authenticated user.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class AnalyticsController : ControllerBase
{
    private readonly IAnalyticsService _analyticsService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<AnalyticsController> _logger;

    public AnalyticsController(
        IAnalyticsService analyticsService,
        ICurrentUserService currentUserService,
        ILogger<AnalyticsController> logger)
    {
        _analyticsService    = analyticsService;
        _currentUserService  = currentUserService;
        _logger              = logger;
    }

    /// <summary>
    /// Returns a spending breakdown for the requested period versus the preceding period.
    /// </summary>
    /// <param name="period">
    ///     The aggregation window: <c>week</c>, <c>month</c>, or <c>year</c>. Required.
    /// </param>
    /// <param name="referenceDate">
    ///     ISO 8601 date (e.g. <c>2026-02-14</c>) that anchors the period window.
    ///     Defaults to today when omitted.
    /// </param>
    /// <param name="cancellationToken">Cancellation token.</param>
    [HttpGet("spending")]
    [ProducesResponseType(typeof(SpendingAnalyticsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<SpendingAnalyticsDto>> GetSpending(
        [FromQuery] string period,
        [FromQuery] DateOnly? referenceDate,
        CancellationToken cancellationToken)
    {
        var normalised = period?.ToLowerInvariant();

        if (normalised is not ("week" or "month" or "year"))
            return Problem(
                detail: "period must be one of: week, month, year.",
                statusCode: StatusCodes.Status400BadRequest);

        _logger.LogDebug(
            "Getting spending analytics for user {UserId} — period={Period}, referenceDate={ReferenceDate}",
            _currentUserService.UserId, normalised, referenceDate);

        var analytics = await _analyticsService
            .GetSpendingAsync(_currentUserService.UserId, normalised, referenceDate, cancellationToken)
            .ConfigureAwait(false);

        return Ok(analytics);
    }
}
