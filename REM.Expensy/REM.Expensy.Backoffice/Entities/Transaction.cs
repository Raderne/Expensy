using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Entities;

public class Transaction : BaseEntity
{
    public Guid WalletId { get; set; }
    public Guid CategoryId { get; set; }
    public decimal Amount { get; set; } = new decimal(0);
    public string MerchantName { get; set; } = null!;
    public string PaymentMethod { get; set; } = null!;
    public DateTime TransactionDate { get; set; }
    public bool UseAutoDate { get; set; } // Whether to automatically use today's date
    public bool IsDraft { get; set; } // Whether the transaction is a draft
    public Wallet Wallet { get; set; } = new Wallet();
    public Category Category { get; set; } = new Category();
}
