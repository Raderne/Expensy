using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using REM.Expensy.Backoffice.Application.Budgets;
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

    builder.Services.AddControllers()
        .AddNewtonsoftJson(options =>
        {
            options.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;
        });
    // Swagger (Development only) — replaces AddOpenApi; document at /swagger/v1/swagger.json
    if (builder.Environment.IsDevelopment())
    {
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen(options =>
        {
            options.SwaggerDoc("v1", new OpenApiInfo { Title = "Expensy Backoffice API", Version = "v1" });
            options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                In = ParameterLocation.Header,
                Description = "JWT: enter your bearer token",
                Name = "Authorization",
                Type = SecuritySchemeType.Http,
                Scheme = "bearer"
            });
            options.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
                    },
                    Array.Empty<string>()
                }
            });
        });
    }

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

    builder.Services.AddScoped<IBudgetQueryService, BudgetQueryService>();

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
        app.UseSwagger();
        app.UseSwaggerUI(options => options.SwaggerEndpoint("/swagger/v1/swagger.json", "Expensy Backoffice API v1"));
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
