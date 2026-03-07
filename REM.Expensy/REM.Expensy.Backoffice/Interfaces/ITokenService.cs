using REM.Expensy.Backoffice.Entities;

namespace REM.Expensy.Backoffice.Interfaces;

public interface ITokenService
{
    string GenerateAccessToken(User user, IList<string> roles);
    string GenerateRefreshToken();
    Task<bool> ValidateRefreshTokenAsync(string userId, string rawToken, CancellationToken ct);
    Task RevokeRefreshTokenAsync(string userId, string rawToken, CancellationToken ct);
    Task SaveRefreshTokenAsync(string userId, string rawToken, CancellationToken ct);
}
