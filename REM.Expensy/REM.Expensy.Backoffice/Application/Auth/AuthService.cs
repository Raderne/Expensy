using Microsoft.AspNetCore.Identity;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Auth;

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly ITokenService _tokenService;

    public AuthService(UserManager<User> userManager, ITokenService tokenService)
    {
        _userManager = userManager;
        _tokenService = tokenService;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct)
    {
        var existing = await _userManager.FindByEmailAsync(request.Email).ConfigureAwait(false);
        if (existing is not null)
            throw new InvalidOperationException("A user with that email already exists.");

        var user = new User
        {
            UserName = request.UserName,
            Email = request.Email,
            Avatar = string.Empty
        };

        var result = await _userManager.CreateAsync(user, request.Password).ConfigureAwait(false);
        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            throw new InvalidOperationException(errors);
        }

        var roles = await _userManager.GetRolesAsync(user).ConfigureAwait(false);
        var accessToken = _tokenService.GenerateAccessToken(user, roles);
        var refreshToken = _tokenService.GenerateRefreshToken();
        await _tokenService.SaveRefreshTokenAsync(user.Id, refreshToken, ct).ConfigureAwait(false);

        return new AuthResponse(accessToken, refreshToken, user.Id, user.Email!);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct)
    {
        var user = await _userManager.FindByEmailAsync(request.Email).ConfigureAwait(false);
        if (user is null || !await _userManager.CheckPasswordAsync(user, request.Password).ConfigureAwait(false))
            throw new UnauthorizedAccessException("Invalid email or password.");

        var roles = await _userManager.GetRolesAsync(user).ConfigureAwait(false);
        var accessToken = _tokenService.GenerateAccessToken(user, roles);
        var refreshToken = _tokenService.GenerateRefreshToken();
        await _tokenService.SaveRefreshTokenAsync(user.Id, refreshToken, ct).ConfigureAwait(false);

        return new AuthResponse(accessToken, refreshToken, user.Id, user.Email!);
    }

    public async Task<AuthResponse> RefreshAsync(RefreshRequest request, CancellationToken ct)
    {
        var valid = await _tokenService.ValidateRefreshTokenAsync(request.UserId, request.RefreshToken, ct).ConfigureAwait(false);
        if (!valid)
            throw new UnauthorizedAccessException("Refresh token is invalid or expired.");

        var user = await _userManager.FindByIdAsync(request.UserId).ConfigureAwait(false);
        if (user is null)
            throw new UnauthorizedAccessException("User not found.");

        await _tokenService.RevokeRefreshTokenAsync(request.UserId, request.RefreshToken, ct).ConfigureAwait(false);

        var roles = await _userManager.GetRolesAsync(user).ConfigureAwait(false);
        var newAccessToken = _tokenService.GenerateAccessToken(user, roles);
        var newRefreshToken = _tokenService.GenerateRefreshToken();
        await _tokenService.SaveRefreshTokenAsync(user.Id, newRefreshToken, ct).ConfigureAwait(false);

        return new AuthResponse(newAccessToken, newRefreshToken, user.Id, user.Email!);
    }

    public async Task RevokeAsync(string userId, string refreshToken, CancellationToken ct)
    {
        await _tokenService.RevokeRefreshTokenAsync(userId, refreshToken, ct).ConfigureAwait(false);
    }
}
