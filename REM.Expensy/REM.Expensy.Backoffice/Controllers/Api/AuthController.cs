using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Auth;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ICurrentUserService _currentUserService;

    public AuthController(IAuthService authService, ICurrentUserService currentUserService)
    {
        _authService = authService;
        _currentUserService = currentUserService;
    }

    [HttpPost("register")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.RegisterAsync(request, cancellationToken).ConfigureAwait(false);
            return CreatedAtAction(nameof(Register), response);
        }
        catch (InvalidOperationException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.LoginAsync(request, cancellationToken).ConfigureAwait(false);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status401Unauthorized);
        }
    }

    [HttpPost("refresh")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Refresh([FromBody] RefreshRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.RefreshAsync(request, cancellationToken).ConfigureAwait(false);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status401Unauthorized);
        }
    }

    [Authorize]
    [HttpPost("revoke")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Revoke([FromBody] string refreshToken, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (string.IsNullOrEmpty(userId))
            return Problem(detail: "Could not resolve current user.", statusCode: StatusCodes.Status400BadRequest);

        await _authService.RevokeAsync(userId, refreshToken, cancellationToken).ConfigureAwait(false);
        return NoContent();
    }
}
