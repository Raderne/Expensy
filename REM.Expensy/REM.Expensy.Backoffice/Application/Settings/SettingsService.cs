using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Settings;

public class SettingsService(IContext context) : ISettingsService
{
    private readonly IContext _context = context;

    public IReadOnlyList<CurrencyDto> GetCurrencies()
    {
        // Static data — no async, no DB
        return CurrencyRepository.All;
    }

    public async Task<IReadOnlyList<SubscriptionCycleDto>> GetSubscriptionCyclesAsync(
        CancellationToken ct = default)
    {
        return await _context.SubscriptionCycles
            .AsNoTracking()
            .OrderBy(c => c.Id)
            .Select(c => new SubscriptionCycleDto(c.Id, c.Code.ToString(), c.Name))
            .ToListAsync(ct)
            .ConfigureAwait(false);
    }
}