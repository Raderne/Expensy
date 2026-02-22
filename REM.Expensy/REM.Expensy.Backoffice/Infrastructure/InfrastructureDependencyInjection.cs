using Microsoft.EntityFrameworkCore;

namespace REM.Expensy.Backoffice.Infrastructure;

public static class InfrastructureDependencyInjection
{
    public static IServiceCollection AddContext<TContext, TIContext>(this IServiceCollection services, IConfiguration configuration)
            where TContext : DbContext, TIContext
            where TIContext : class
    {
        var connectionString = configuration.GetConnectionString(typeof(TContext).Name);
        services.AddDbContext<TContext>(options =>
        {
            options.UseNpgsql(connectionString, npgsqlOptions =>
            {
                npgsqlOptions.EnableRetryOnFailure();
            });

            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
            if (environment == "Development")
            {
                options.EnableSensitiveDataLogging();
                options.EnableDetailedErrors();
            }
        });

        services.AddScoped<TIContext>(provider => provider.GetService<TContext>()!);

        return services;
    }

    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {


        return services;
    }
}
