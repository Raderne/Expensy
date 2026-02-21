using Microsoft.AspNetCore.Identity;

namespace REM.Expensy.Backoffice.Entities;

public class User : IdentityUser
{
    public string Avatar { get; set; } = null!;
}
