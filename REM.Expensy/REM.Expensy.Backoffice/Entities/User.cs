using Microsoft.AspNetCore.Identity;

namespace REM.Expensy.Backoffice.Entities;

public class User : IdentityUser
{
    public string Avatar { get; set; } = null!;
    public string CurrencyCode { get; set; } = "USD";
    public string? NotificationPreferences { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
}
