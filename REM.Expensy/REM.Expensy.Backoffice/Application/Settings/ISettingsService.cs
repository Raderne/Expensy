namespace REM.Expensy.Backoffice.Application.Settings;

public interface ISettingsService
{
    IReadOnlyList<CurrencyDto> GetCurrencies();
    Task<IReadOnlyList<SubscriptionCycleDto>> GetSubscriptionCyclesAsync(CancellationToken ct = default);
}
