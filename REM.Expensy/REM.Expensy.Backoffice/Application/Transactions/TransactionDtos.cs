namespace REM.Expensy.Backoffice.Application.Transactions;

/// <summary>
/// Read model returned from transaction queries.
/// </summary>
public record TransactionDto(
    Guid Id,
    Guid WalletId,
    string WalletName,
    Guid CategoryId,
    string CategoryName,
    string CategoryColor,
    string CategoryIcon,
    decimal Amount,
    string MerchantName,
    string PaymentMethod,
    DateTime TransactionDate,
    bool IsDraft,
    DateTime Created);

/// <summary>
/// Payload for creating a new transaction.
/// </summary>
public record CreateTransactionRequest(
    Guid WalletId,
    Guid CategoryId,
    decimal Amount,
    string MerchantName,
    string PaymentMethod,
    DateTime? TransactionDate,
    bool IsDraft);

/// <summary>
/// Payload for updating an existing transaction.
/// </summary>
public record UpdateTransactionRequest(
    Guid CategoryId,
    decimal Amount,
    string MerchantName,
    string PaymentMethod,
    DateTime? TransactionDate,
    bool IsDraft);
