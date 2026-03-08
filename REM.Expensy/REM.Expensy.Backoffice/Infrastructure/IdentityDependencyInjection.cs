using Microsoft.AspNetCore.Identity;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Infrastructure.Context;

namespace REM.Expensy.Backoffice.Infrastructure;

public static class IdentityDependencyInjection
{
    public static IServiceCollection AddIdentityConfiguration(this IServiceCollection services)
    {
        services.AddIdentityCore<User>(options =>
        {
            options.Password.RequiredLength = 8;
            options.Password.RequireDigit = true;
            options.Password.RequireNonAlphanumeric = false;
            options.Lockout.MaxFailedAccessAttempts = 5;
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
            options.User.RequireUniqueEmail = true;
        })
        .AddRoles<IdentityRole>()
        .AddEntityFrameworkStores<ApplicationContext>();

        return services;
    }
}
