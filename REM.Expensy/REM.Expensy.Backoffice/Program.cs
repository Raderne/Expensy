using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using REM.Expensy.Backoffice.Infrastructure;
using REM.Expensy.Backoffice.Infrastructure.Context;
using REM.Expensy.Backoffice.Infrastructure.Services;
using REM.Expensy.Backoffice.Interfaces;
using Serilog;

// Bootstrap Serilog from configuration
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

    // DbContext and infrastructure
    builder.Services.AddContext<ApplicationContext, IContext>(builder.Configuration);
    builder.Services.AddInfrastructure(builder.Configuration);

    builder.Services.AddHttpContextAccessor();
    builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();

    builder.Services.AddControllers();
    builder.Services.AddOpenApi();

    // JWT
    var jwtSection = builder.Configuration.GetSection("JwtSettings");
    var issuer = jwtSection["Issuer"] ?? "https://localhost:7001";
    var audience = jwtSection["Audience"] ?? "ExpensyBackoffice";
    var key = jwtSection["Key"] ?? throw new InvalidOperationException("JwtSettings:Key is required (set via User Secrets or environment).");
    var keyBytes = Encoding.UTF8.GetBytes(key);

    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = issuer,
                ValidAudience = audience,
                IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
                ClockSkew = TimeSpan.Zero
            };
        });
    builder.Services.AddAuthorization();

    // Health checks (PostgreSQL)
    var connectionString = builder.Configuration.GetConnectionString(nameof(ApplicationContext));
    if (!string.IsNullOrEmpty(connectionString))
    {
        builder.Services.AddHealthChecks()
            .AddNpgSql(connectionString, name: "postgres");
    }

    // CORS
    var corsSection = builder.Configuration.GetSection("Cors");
    var allowedOrigins = corsSection.GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
    var policyName = corsSection["PolicyName"] ?? "ExpensyCors";

    builder.Services.AddCors(options =>
    {
        options.AddPolicy(policyName, policy =>
        {
            policy.WithOrigins(allowedOrigins)
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        });
    });

    var app = builder.Build();

    app.UseSerilogRequestLogging();

    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();
    }

    app.UseHttpsRedirection();
    app.UseCors(policyName);
    app.UseAuthentication();
    app.UseAuthorization();

    app.MapControllers();

    if (!string.IsNullOrEmpty(connectionString))
    {
        app.MapHealthChecks("/health");
    }

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
