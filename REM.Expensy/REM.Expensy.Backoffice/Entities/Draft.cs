using REM.Expensy.Backoffice.Entities.Common;
using System.Text.Json;

namespace REM.Expensy.Backoffice.Entities;

public class Draft : BaseEntity
{
    public string UserId { get; set; } = null!;
    public JsonDocument Data { get; set; }
}
