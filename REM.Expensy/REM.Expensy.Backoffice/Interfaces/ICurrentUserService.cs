namespace REM.Expensy.Backoffice.Interfaces
{
    public interface ICurrentUserService
    {
        string UserId { get; }
        public string UserName { get; }
        public string PreferredUsername { get; }
        public string Email { get; }
        List<string> RoleNames { get; }

        public bool IsLoggedIn()
        {
            return !string.IsNullOrEmpty(UserId);
        }
    }
}
