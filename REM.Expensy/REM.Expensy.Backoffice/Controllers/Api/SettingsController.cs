using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Settings;

namespace REM.Expensy.Backoffice.Controllers.Api;

[ApiController]
[AllowAnonymous]
[Route("api/settings")]
public class SettingsController : ControllerBase
{
    private readonly ISettingsService _settingsService;

    public SettingsController(ISettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    // GET api/settings/currencies
    [HttpGet("currencies")]
    [ResponseCache(Duration = 86400, Location = ResponseCacheLocation.Any)]
    [ProducesResponseType(typeof(IReadOnlyList<CurrencyDto>), StatusCodes.Status200OK)]
    public IActionResult GetCurrencies()
    {
        var currencies = _settingsService.GetCurrencies();
        return Ok(currencies);
    }

    // GET api/settings/subscription-cycles
    [HttpGet("subscription-cycles")]
    [ResponseCache(Duration = 86400, Location = ResponseCacheLocation.Any)]
    [ProducesResponseType(typeof(IReadOnlyList<SubscriptionCycleDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSubscriptionCycles(CancellationToken ct)
    {
        var cycles = await _settingsService.GetSubscriptionCyclesAsync(ct);
        return Ok(cycles);
    }
}