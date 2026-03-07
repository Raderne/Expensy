namespace REM.Expensy.Backoffice.Application.Wallets;

/// <summary>
/// Read model returned from wallet queries.
/// </summary>
public record WalletDto(Guid Id, string Name, decimal Balance, string Icon, string UserId);

/// <summary>
/// Payload for creating a new wallet.
/// </summary>
public record CreateWalletRequest(string Name, decimal InitialBalance, string Icon);

/// <summary>
/// Payload for updating an existing wallet's metadata. Balance is managed by transactions, not this request.
/// </summary>
public record UpdateWalletRequest(string Name, string Icon);
