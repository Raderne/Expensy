using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Transactions;

/// <summary>
/// Handles CRUD operations for transactions, scoped to the requesting user via wallet ownership.
/// </summary>
public class TransactionService : ITransactionService
{
    private readonly IContext _context;

    public TransactionService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<TransactionDto>> GetAllForUserAsync(string userId, CancellationToken ct = default)
    {
        var transactions = await _context.Transactions
            .AsNoTracking()
            .Where(t => t.Wallet.UserId == userId)
            .OrderByDescending(t => t.TransactionDate)
            .Select(t => new TransactionDto(
                t.Id,
                t.WalletId,
                t.Wallet.Name,
                t.CategoryId,
                t.Category.Name,
                t.Category.Color,
                t.Category.Icon,
                t.Amount,
                t.MerchantName,
                t.PaymentMethod,
                t.TransactionDate,
                t.IsDraft,
                t.Created))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return transactions;
    }

    /// <inheritdoc/>
    public async Task<TransactionDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var transaction = await _context.Transactions
            .AsNoTracking()
            .Where(t => t.Id == id && t.Wallet.UserId == userId)
            .Select(t => new TransactionDto(
                t.Id,
                t.WalletId,
                t.Wallet.Name,
                t.CategoryId,
                t.Category.Name,
                t.Category.Color,
                t.Category.Icon,
                t.Amount,
                t.MerchantName,
                t.PaymentMethod,
                t.TransactionDate,
                t.IsDraft,
                t.Created))
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        return transaction;
    }

    /// <inheritdoc/>
    public async Task<TransactionDto> CreateAsync(CreateTransactionRequest request, string userId, CancellationToken ct = default)
    {
        var walletBelongsToUser = await _context.Wallets
            .AsNoTracking()
            .AnyAsync(w => w.Id == request.WalletId && w.UserId == userId, ct)
            .ConfigureAwait(false);

        if (!walletBelongsToUser)
            throw new InvalidOperationException($"Wallet '{request.WalletId}' does not belong to the current user.");

        var transaction = new Transaction
        {
            WalletId = request.WalletId,
            CategoryId = request.CategoryId,
            Amount = request.Amount,
            MerchantName = request.MerchantName,
            PaymentMethod = request.PaymentMethod,
            TransactionDate = request.TransactionDate ?? DateTime.UtcNow,
            UseAutoDate = request.TransactionDate is null,
            IsDraft = request.IsDraft
        };

        await _context.Transactions.AddAsync(transaction, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        // Re-query with navigation properties so the DTO is fully populated.
        var dto = await GetByIdAsync(transaction.Id, userId, ct).ConfigureAwait(false);

        return dto!;
    }

    /// <inheritdoc/>
    public async Task<TransactionDto?> UpdateAsync(Guid id, UpdateTransactionRequest request, string userId, CancellationToken ct = default)
    {
        var transaction = await _context.Transactions
            .Where(t => t.Id == id && t.Wallet.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (transaction is null)
            return null;

        var categoryIsAvailable = await _context.Categories
            .AsNoTracking()
            .AnyAsync(c => c.Id == request.CategoryId, ct)
            .ConfigureAwait(false);

        if (!categoryIsAvailable)
            throw new InvalidOperationException($"Category '{request.CategoryId}' is not available for the current user.");

        transaction.CategoryId = request.CategoryId;
        transaction.Amount = request.Amount;
        transaction.MerchantName = request.MerchantName;
        transaction.PaymentMethod = request.PaymentMethod;
        transaction.TransactionDate = request.TransactionDate ?? DateTime.UtcNow;
        transaction.UseAutoDate = request.TransactionDate is null;
        transaction.IsDraft = request.IsDraft;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        var dto = await GetByIdAsync(transaction.Id, userId, ct).ConfigureAwait(false);

        return dto;
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var transaction = await _context.Transactions
            .Where(t => t.Id == id && t.Wallet.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (transaction is null)
            return false;

        transaction.IsDeleted = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }
}
