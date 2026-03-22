using REM.Expensy.Backoffice.Application.Analytics;
using REM.Expensy.Backoffice.Application.Auth;
using REM.Expensy.Backoffice.Application.Budgets;
using REM.Expensy.Backoffice.Application.Categories;
using REM.Expensy.Backoffice.Application.Dashboard;
using REM.Expensy.Backoffice.Application.Notifications;
using REM.Expensy.Backoffice.Application.Profile;
using REM.Expensy.Backoffice.Application.SavingsGoals;
using REM.Expensy.Backoffice.Application.Settings;
using REM.Expensy.Backoffice.Application.Subscriptions;
using REM.Expensy.Backoffice.Application.Transactions;
using REM.Expensy.Backoffice.Application.Wallets;
using REM.Expensy.Backoffice.Infrastructure.Json;
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
        services.AddScoped<IDataSeeder, DataSeeder>();

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

        // Phase 3
        services.AddScoped<IDashboardService, DashboardService>();
        services.AddScoped<IAnalyticsService, AnalyticsService>();

        // Phase 4
        services.AddScoped<IMilestoneProgressionService, MilestoneProgressionService>();

        // Phase 5 — Profile & Settings
        services.AddScoped<IProfileService, ProfileService>();
        services.AddScoped<ISettingsService, SettingsService>();

        services.AddControllers()
            .AddNewtonsoftJson(options =>
            {
                options.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;
                options.SerializerSettings.Converters.Add(new DateOnlyJsonConverter());
            });

        return services;
    }
}
