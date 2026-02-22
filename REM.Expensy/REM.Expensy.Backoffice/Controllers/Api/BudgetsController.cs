using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Budgets;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// API for budget read operations.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class BudgetsController : ControllerBase
{
    private readonly IBudgetQueryService _budgetQueryService;
    private readonly ILogger<BudgetsController> _logger;

    public BudgetsController(IBudgetQueryService budgetQueryService, ILogger<BudgetsController> logger)
    {
        _budgetQueryService = budgetQueryService;
        _logger = logger;
    }

    /// <summary>
    /// Get all budgets.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>List of budget DTOs.</returns>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<BudgetDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<ActionResult<IReadOnlyList<BudgetDto>>> GetAll(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting all budgets");
        var budgets = await _budgetQueryService.GetAllAsync(cancellationToken).ConfigureAwait(false);
        return Ok(budgets);
    }
}
