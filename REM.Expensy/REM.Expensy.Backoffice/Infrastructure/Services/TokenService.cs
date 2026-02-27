using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Infrastructure.Services;

public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;
    private readonly IContext _context;

    public TokenService(IConfiguration configuration, IContext context)
    {
        _configuration = configuration;
        _context = context;
    }

    public string GenerateAccessToken(User user, IList<string> roles)
    {
        var section = _configuration.GetSection("JwtSettings");
        var issuer = section["Issuer"] ?? "https://localhost:7001";
        var audience = section["Audience"] ?? "ExpensyBackoffice";
        var key = section["Key"] ?? throw new InvalidOperationException("JwtSettings:Key is required.");
        var keyBytes = Encoding.UTF8.GetBytes(key);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Name, user.UserName ?? string.Empty),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        foreach (var role in roles)
            claims.Add(new Claim(ClaimTypes.Role, role));

        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(keyBytes),
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        return Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    }

    public async Task<bool> ValidateRefreshTokenAsync(string userId, string rawToken, CancellationToken ct)
    {
        var hash = HashToken(rawToken);

        var token = await _context.RefreshTokens
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.UserId == userId && t.TokenHash == hash, ct)
            .ConfigureAwait(false);

        return token is not null && !token.IsRevoked && token.Expiry > DateTime.UtcNow;
    }

    public async Task RevokeRefreshTokenAsync(string userId, string rawToken, CancellationToken ct)
    {
        var hash = HashToken(rawToken);

        var token = await _context.RefreshTokens
            .FirstOrDefaultAsync(t => t.UserId == userId && t.TokenHash == hash, ct)
            .ConfigureAwait(false);

        if (token is null) return;

        token.IsRevoked = true;
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);
    }

    public async Task SaveRefreshTokenAsync(string userId, string rawToken, CancellationToken ct)
    {
        var entry = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            TokenHash = HashToken(rawToken),
            Expiry = DateTime.UtcNow.AddDays(7),
            IsRevoked = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.RefreshTokens.Add(entry);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);
    }

    private static string HashToken(string rawToken)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken));
        return Convert.ToBase64String(bytes);
    }
}
