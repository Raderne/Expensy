using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Infrastructure.Services;

public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public string UserId => _httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? _httpContextAccessor.HttpContext?.User?.FindFirstValue("sub") ?? string.Empty;

    public string UserName => _httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.Name)
        ?? _httpContextAccessor.HttpContext?.User?.FindFirstValue("name") ?? string.Empty;

    public string PreferredUsername => _httpContextAccessor.HttpContext?.User?.FindFirstValue("preferred_username") ?? string.Empty;

    public string Email => _httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.Email)
        ?? _httpContextAccessor.HttpContext?.User?.FindFirstValue("email") ?? string.Empty;

    public List<string> RoleNames => _httpContextAccessor.HttpContext?.User?.FindAll(ClaimTypes.Role)
        .Select(c => c.Value).ToList() ?? _httpContextAccessor.HttpContext?.User?.FindAll("role")
        .Select(c => c.Value).ToList() ?? new List<string>();
}
