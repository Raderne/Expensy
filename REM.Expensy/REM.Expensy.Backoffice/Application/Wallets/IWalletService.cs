namespace REM.Expensy.Backoffice.Application.Wallets;

/// <summary>
/// CRUD service for wallets, scoped to the requesting user.
/// </summary>
public interface IWalletService
{
    /// <summary>
    /// Returns all wallets owned by the specified user.
    /// </summary>
    Task<IReadOnlyList<WalletDto>> GetAllForUserAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns a single wallet by ID, or <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<WalletDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Creates a new wallet for the user. Initial balance is set from the request.
    /// </summary>
    Task<WalletDto> CreateAsync(CreateWalletRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Updates name and icon of an existing wallet. Returns <see langword="null"/> if not found or not owned by the user.
    /// </summary>
    Task<WalletDto?> UpdateAsync(Guid id, UpdateWalletRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Soft-deletes a wallet. Returns <see langword="false"/> if not found or not owned by the user.
    /// </summary>
    Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default);
}
