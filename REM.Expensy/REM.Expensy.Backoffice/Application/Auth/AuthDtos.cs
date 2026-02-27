namespace REM.Expensy.Backoffice.Application.Auth;

public record RegisterRequest(string Email, string Password, string UserName);
public record LoginRequest(string Email, string Password);
public record AuthResponse(string AccessToken, string RefreshToken, string UserId, string Email);
public record RefreshRequest(string UserId, string RefreshToken);
