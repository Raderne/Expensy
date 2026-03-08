using REM.Expensy.Backoffice.Infrastructure;
using REM.Expensy.Backoffice.Infrastructure.Services;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(new ConfigurationBuilder()
        .AddJsonFile("appsettings.json", false, true)
        .AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"}.json", true)
        .AddEnvironmentVariables()
        .Build())
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);
    builder.Host.UseSerilog();

    builder.Services.AddInfrastructure(builder.Configuration);
    builder.Services.AddIdentityConfiguration();
    builder.Services.AddJwtAuthentication(builder.Configuration);
    builder.Services.AddAppHealthChecks(builder.Configuration);
    builder.Services.AddCorsPolicy(builder.Configuration);
    builder.Services.AddApplicationServices();

    if (builder.Environment.IsDevelopment())
    {
        builder.Services.AddSwaggerDocumentation();
        builder.Services.AddOpenApiDocument(); // required for NSwag code generation
    }

    var app = builder.Build();

    // Seed required data on every startup (idempotent)
    using (var scope = app.Services.CreateScope())
    {
        var seeder = scope.ServiceProvider.GetRequiredService<IDataSeeder>();
        await seeder.SeedAsync();
    }

    app.UseBackofficePipeline();
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
    throw;
}
finally
{
    Log.CloseAndFlush();
}
