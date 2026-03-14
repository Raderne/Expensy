using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Dashboard;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// Provides the aggregated dashboard summary for the authenticated user.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<DashboardController> _logger;

    public DashboardController(
        IDashboardService dashboardService,
        ICurrentUserService currentUserService,
        ILogger<DashboardController> logger)
    {
        _dashboardService    = dashboardService;
        _currentUserService  = currentUserService;
        _logger              = logger;
    }

    /// <summary>
    /// Returns the dashboard summary for the specified month and year.
    /// Includes monthly balance, total expenses, weekly spending chart, and recent transactions.
    /// </summary>
    /// <param name="month">Calendar month (1–12). Defaults to the current month.</param>
    /// <param name="year">Four-digit year. Defaults to the current year.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    [HttpGet("summary")]
    [ProducesResponseType(typeof(DashboardSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<DashboardSummaryDto>> GetSummary(
        [FromQuery] int? month,
        [FromQuery] int? year,
        CancellationToken cancellationToken)
    {
        var now           = DateTime.UtcNow;
        var resolvedMonth = month ?? now.Month;
        var resolvedYear  = year  ?? now.Year;

        if (resolvedMonth is < 1 or > 12)
            return Problem(
                detail: "month must be between 1 and 12.",
                statusCode: StatusCodes.Status400BadRequest);

        if (resolvedYear < 2000 || resolvedYear > 2100)
            return Problem(
                detail: "year must be a reasonable four-digit value.",
                statusCode: StatusCodes.Status400BadRequest);

        _logger.LogDebug(
            "Getting dashboard summary for user {UserId} — {Month}/{Year}",
            _currentUserService.UserId, resolvedMonth, resolvedYear);

        var summary = await _dashboardService
            .GetSummaryAsync(_currentUserService.UserId, resolvedMonth, resolvedYear, cancellationToken)
            .ConfigureAwait(false);

        return Ok(summary);
    }
}
