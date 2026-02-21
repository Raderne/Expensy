using REM.Expensy.Backoffice.Entities.Common;
using System.Text.Json;

namespace REM.Expensy.Backoffice.Entities;

public class Draft : BaseEntity
{
    public Guid UserId { get; set; }
    public JsonDocument Data { get; set; }
}
