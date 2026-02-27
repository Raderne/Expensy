using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Wallets;

/// <summary>
/// Handles CRUD operations for wallets, scoped to the requesting user.
/// </summary>
public class WalletService : IWalletService
{
    private readonly IContext _context;

    public WalletService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<WalletDto>> GetAllForUserAsync(string userId, CancellationToken ct = default)
    {
        var wallets = await _context.Wallets
            .AsNoTracking()
            .Where(w => w.UserId == userId)
            .OrderBy(w => w.Name)
            .Select(w => new WalletDto(w.Id, w.Name, w.Balance, w.Icon, w.UserId))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return wallets;
    }

    /// <inheritdoc/>
    public async Task<WalletDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var wallet = await _context.Wallets
            .AsNoTracking()
            .Where(w => w.Id == id && w.UserId == userId)
            .Select(w => new WalletDto(w.Id, w.Name, w.Balance, w.Icon, w.UserId))
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        return wallet;
    }

    /// <inheritdoc/>
    public async Task<WalletDto> CreateAsync(CreateWalletRequest request, string userId, CancellationToken ct = default)
    {
        var wallet = new Wallet
        {
            Name = request.Name,
            Balance = request.InitialBalance,
            Icon = request.Icon,
            UserId = userId
        };

        await _context.Wallets.AddAsync(wallet, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return new WalletDto(wallet.Id, wallet.Name, wallet.Balance, wallet.Icon, wallet.UserId);
    }

    /// <inheritdoc/>
    public async Task<WalletDto?> UpdateAsync(Guid id, UpdateWalletRequest request, string userId, CancellationToken ct = default)
    {
        var wallet = await _context.Wallets
            .Where(w => w.Id == id && w.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (wallet is null)
            return null;

        wallet.Name = request.Name;
        wallet.Icon = request.Icon;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return new WalletDto(wallet.Id, wallet.Name, wallet.Balance, wallet.Icon, wallet.UserId);
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var wallet = await _context.Wallets
            .Where(w => w.Id == id && w.UserId == userId)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (wallet is null)
            return false;

        wallet.IsDeleted = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }
}
