using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Logging.Abstractions;
using REM.Expensy.Backoffice.Infrastructure.Services;
using System.Reflection;

namespace REM.Expensy.Backoffice.Infrastructure.Context;

public class ApplicationContextFactory : IDesignTimeDbContextFactory<ApplicationContext>
{
    public ApplicationContext CreateDbContext(string[] args)
    {
        return Activator.CreateInstance(typeof(ApplicationContext), GetParams()) as ApplicationContext ?? null!;
    }

    protected DbContextOptions<ApplicationContext> BuildDbContextOptions()
    {
        var configurationRoot = GetConfigurationRoot();
        var connectionString = configurationRoot.GetConnectionString(typeof(ApplicationContext).Name) ?? "";
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationContext>();
        optionsBuilder.EnableSensitiveDataLogging(true);
        optionsBuilder.UseNpgsql(connectionString,
            b => b.MigrationsAssembly(Assembly.GetAssembly(typeof(ApplicationContext))?.GetName().FullName));

        return optionsBuilder.Options;
    }

    /// <summary>
    /// Parameters must match ApplicationContext constructor: (DbContextOptions, ILogger, ICurrentUserService).
    /// </summary>
    protected object?[] GetParams()
    {
        return
        [
            BuildDbContextOptions(),
            NullLogger<ApplicationContext>.Instance,
            new NullCurrentUserService()
        ];
    }


    protected IConfigurationRoot GetConfigurationRoot()
    {
        var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production";
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Path.Combine(Directory.GetCurrentDirectory(), GetAppSettingsProject()))
            .AddJsonFile("appsettings.json", false, true)
            .AddJsonFile($"appsettings.{environment}.json", true)
            .AddEnvironmentVariables()
            .Build();

        return configuration;
    }

    protected string GetAppSettingsProject()
    {
        return string.Empty;
    }
}
