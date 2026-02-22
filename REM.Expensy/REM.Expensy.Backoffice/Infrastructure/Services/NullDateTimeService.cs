namespace REM.Expensy.Backoffice.Infrastructure.Services
{
    public class NullDateTimeService
    {
        public DateTime Now => DateTime.UtcNow;
    }
}
