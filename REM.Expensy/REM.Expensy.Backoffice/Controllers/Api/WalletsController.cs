using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Wallets;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// CRUD endpoints for wallets. All operations are scoped to the authenticated user.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class WalletsController : ControllerBase
{
    private readonly IWalletService _walletService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<WalletsController> _logger;

    public WalletsController(
        IWalletService walletService,
        ICurrentUserService currentUserService,
        ILogger<WalletsController> logger)
    {
        _walletService = walletService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Returns all wallets owned by the current user.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<WalletDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<WalletDto>>> GetAll(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting all wallets for user {UserId}", _currentUserService.UserId);

        var wallets = await _walletService
            .GetAllForUserAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(wallets);
    }

    /// <summary>
    /// Returns a single wallet by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(WalletDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WalletDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting wallet {WalletId} for user {UserId}", id, _currentUserService.UserId);

        var wallet = await _walletService
            .GetByIdAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (wallet is null)
            return NotFound();

        return Ok(wallet);
    }

    /// <summary>
    /// Creates a new wallet for the current user.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(WalletDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<WalletDto>> Create([FromBody] CreateWalletRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Creating wallet for user {UserId}", _currentUserService.UserId);

        var wallet = await _walletService
            .CreateAsync(request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return CreatedAtAction(nameof(GetById), new { id = wallet.Id }, wallet);
    }

    /// <summary>
    /// Updates the name and icon of an existing wallet. Balance is managed by transactions.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(WalletDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WalletDto>> Update(Guid id, [FromBody] UpdateWalletRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Updating wallet {WalletId} for user {UserId}", id, _currentUserService.UserId);

        var wallet = await _walletService
            .UpdateAsync(id, request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (wallet is null)
            return NotFound();

        return Ok(wallet);
    }

    /// <summary>
    /// Soft-deletes a wallet.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Deleting wallet {WalletId} for user {UserId}", id, _currentUserService.UserId);

        var deleted = await _walletService
            .DeleteAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}
