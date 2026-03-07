namespace REM.Expensy.Backoffice.Application.Transactions;

/// <summary>
/// CRUD service for transactions, scoped to the requesting user via wallet ownership.
/// </summary>
public interface ITransactionService
{
    /// <summary>
    /// Returns all transactions belonging to wallets owned by the user, ordered by TransactionDate descending.
    /// </summary>
    Task<IReadOnlyList<TransactionDto>> GetAllForUserAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns a single transaction by ID, or <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<TransactionDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Creates a new transaction. Verifies the target wallet belongs to the user before persisting.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when the wallet does not belong to the user.</exception>
    Task<TransactionDto> CreateAsync(CreateTransactionRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Updates an existing transaction. Returns <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<TransactionDto?> UpdateAsync(Guid id, UpdateTransactionRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Soft-deletes a transaction. Returns <see langword="false"/> if not found or not owned by the user.
    /// </summary>
    Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default);
}
