using Newtonsoft.Json;

namespace REM.Expensy.Backoffice.Infrastructure.Json;

public class DateOnlyJsonConverter : JsonConverter<DateOnly>
{
    private const string Format = "yyyy-MM-dd";

    public override DateOnly ReadJson(JsonReader reader, Type objectType, DateOnly existingValue, bool hasExistingValue, JsonSerializer serializer)
    {
        var value = reader.Value?.ToString();
        if (string.IsNullOrWhiteSpace(value))
            return default;

        if (DateTime.TryParse(value, out var dateTime))
            return DateOnly.FromDateTime(dateTime);

        return DateOnly.Parse(value);
    }

    public override void WriteJson(JsonWriter writer, DateOnly value, JsonSerializer serializer)
    {
        writer.WriteValue(value.ToString(Format));
    }
}
