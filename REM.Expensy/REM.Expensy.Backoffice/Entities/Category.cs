using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Entities;

public class Category : BaseEntity
{
    public string Name { get; set; } = null!;
    public string Icon { get; set; } = null!;
    public string Color { get; set; } = null!;
    public bool IsSystem { get; set; }
    public string? UserId { get; set; }
    public User? User { get; set; }
}
