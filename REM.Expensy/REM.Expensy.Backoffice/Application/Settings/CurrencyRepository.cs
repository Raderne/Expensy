namespace REM.Expensy.Backoffice.Application.Settings;

/// <summary>
/// In-memory static list of supported ISO 4217 currencies.
/// No database query required — this list is fixed at compile time.
/// </summary>
public static class CurrencyRepository
{
    public static readonly IReadOnlyList<CurrencyDto> All = new List<CurrencyDto>
    {
        new("USD", "US Dollar", "$"),
        new("EUR", "Euro", "€"),
        new("GBP", "British Pound", "£"),
        new("TRY", "Turkish Lira", "₺"),
        new("MAD", "Moroccan Dirham", "MAD"),
    }.AsReadOnly();
}