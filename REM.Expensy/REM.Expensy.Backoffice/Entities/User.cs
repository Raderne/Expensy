using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Entities;

public class User : BaseEntity
{
    public string Name { get; set; } = null!;
    public string Avatar { get; set; } = null!;
}
