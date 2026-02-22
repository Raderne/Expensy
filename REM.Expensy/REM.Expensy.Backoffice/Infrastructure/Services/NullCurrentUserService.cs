using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Infrastructure.Services
{
    public class NullCurrentUserService : ICurrentUserService
    {
        public string UserId => string.Empty;
        public string UserName => string.Empty;
        public string PreferredUsername => string.Empty;
        public string Email => string.Empty;
        public List<string> RoleNames => new List<string>();
    }
}
