using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Transactions;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// CRUD endpoints for transactions. All operations are scoped to the authenticated user via wallet ownership.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class TransactionsController : ControllerBase
{
    private readonly ITransactionService _transactionService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<TransactionsController> _logger;

    public TransactionsController(
        ITransactionService transactionService,
        ICurrentUserService currentUserService,
        ILogger<TransactionsController> logger)
    {
        _transactionService = transactionService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Returns all transactions for wallets owned by the current user, ordered by date descending.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<TransactionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<TransactionDto>>> GetAll(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting all transactions for user {UserId}", _currentUserService.UserId);

        var transactions = await _transactionService
            .GetAllForUserAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(transactions);
    }

    /// <summary>
    /// Returns a single transaction by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(TransactionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TransactionDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting transaction {TransactionId} for user {UserId}", id, _currentUserService.UserId);

        var transaction = await _transactionService
            .GetByIdAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (transaction is null)
            return NotFound();

        return Ok(transaction);
    }

    /// <summary>
    /// Creates a new transaction. The wallet must belong to the current user.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(TransactionDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<TransactionDto>> Create([FromBody] CreateTransactionRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Creating transaction for user {UserId} in wallet {WalletId}", _currentUserService.UserId, request.WalletId);

        try
        {
            var transaction = await _transactionService
                .CreateAsync(request, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            return CreatedAtAction(nameof(GetById), new { id = transaction.Id }, transaction);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Business rule violation creating transaction for user {UserId}", _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    /// <summary>
    /// Updates an existing transaction.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(TransactionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TransactionDto>> Update(Guid id, [FromBody] UpdateTransactionRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Updating transaction {TransactionId} for user {UserId}", id, _currentUserService.UserId);

        var transaction = await _transactionService
            .UpdateAsync(id, request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (transaction is null)
            return NotFound();

        return Ok(transaction);
    }

    /// <summary>
    /// Soft-deletes a transaction.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Deleting transaction {TransactionId} for user {UserId}", id, _currentUserService.UserId);

        var deleted = await _transactionService
            .DeleteAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}
