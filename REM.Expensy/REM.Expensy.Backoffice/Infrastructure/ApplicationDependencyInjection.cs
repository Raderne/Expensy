using REM.Expensy.Backoffice.Application.Auth;
using REM.Expensy.Backoffice.Application.Budgets;
using REM.Expensy.Backoffice.Application.Categories;
using REM.Expensy.Backoffice.Application.Transactions;
using REM.Expensy.Backoffice.Application.Wallets;
using REM.Expensy.Backoffice.Infrastructure.Services;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Infrastructure;

public static class ApplicationDependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IBudgetQueryService, BudgetQueryService>();
        services.AddScoped<IWalletService, WalletService>();
        services.AddScoped<ITransactionService, TransactionService>();
        services.AddScoped<ICategoryService, CategoryService>();

        services.AddControllers()
            .AddNewtonsoftJson(options =>
            {
                options.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;
            });

        return services;
    }
}
