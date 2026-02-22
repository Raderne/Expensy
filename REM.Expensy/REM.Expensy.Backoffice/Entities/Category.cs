using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Entities;

public class Category : BaseEntity
{
    public string Name { get; set; } = null!;
    public string Icon { get; set; } = null!;
    public string Color { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public User User { get; set; } = null!;
}
