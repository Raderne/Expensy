using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Entities;

public class Wallet : BaseEntity
{
    public string Name { get; set; } = null!;
    public decimal Balance { get; set; }
    public string Icon { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public User User { get; set; } = null!;
}
