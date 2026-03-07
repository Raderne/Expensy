using REM.Expensy.Backoffice.Application.Auth;
using REM.Expensy.Backoffice.Application.Budgets;
using REM.Expensy.Backoffice.Application.Categories;
using REM.Expensy.Backoffice.Application.Notifications;
using REM.Expensy.Backoffice.Application.SavingsGoals;
using REM.Expensy.Backoffice.Application.Subscriptions;
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

        // Phase 1
        services.AddScoped<IBudgetQueryService, BudgetQueryService>();
        services.AddScoped<IWalletService, WalletService>();
        services.AddScoped<ITransactionService, TransactionService>();
        services.AddScoped<ICategoryService, CategoryService>();

        // Phase 2
        services.AddScoped<IBudgetService, BudgetService>();
        services.AddScoped<ISavingsGoalService, SavingsGoalService>();
        services.AddScoped<ISubscriptionService, SubscriptionService>();
        services.AddScoped<INotificationService, NotificationService>();

        services.AddControllers()
            .AddNewtonsoftJson(options =>
            {
                options.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;
            });

        return services;
    }
}
