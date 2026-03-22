using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Enums;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Infrastructure.Services;

/// <summary>
/// Idempotent startup seeder that ensures the SuperAdmin role, user, and system categories exist.
/// Safe to call on every application start.
/// </summary>
public interface IDataSeeder
{
    Task SeedAsync();
}

public sealed class DataSeeder : IDataSeeder
{
    private const string SuperAdminRole = "SuperAdmin";
    private const string SuperAdminEmail = "SuperAdmin@expensy.com";
    private const string SuperAdminUserName = "SuperAdmin";
    private const string SuperAdminPassword = "Test@2026";

    private static readonly (BudgetStatusEnum Code, string Title, string Description)[] BudgetStatusSeed =
    [
        (BudgetStatusEnum.OnTrack,    "On Track",    "Spending is within the budget limit."),
        (BudgetStatusEnum.Good,       "Good",        "Spending is well below the budget limit."),
        (BudgetStatusEnum.NearLimit,  "Near Limit",  "Spending is approaching the budget limit."),
        (BudgetStatusEnum.OverBudget, "Over Budget", "Spending has exceeded the budget limit."),
    ];

    private static readonly (MilestoneStatusEnum Code, string Name)[] MilestoneStatusSeed =
    [
        (MilestoneStatusEnum.NotStarted, "Not Started"),
        (MilestoneStatusEnum.InProgress, "In Progress"),
        (MilestoneStatusEnum.Completed,  "Completed"),
    ];

    private static readonly (NotificationTypeEnum Code, string Name)[] NotificationTypeSeed =
    [
        (NotificationTypeEnum.BudgetAlert,      "Budget Alert"),
        (NotificationTypeEnum.RenewalReminder,  "Renewal Reminder"),
        (NotificationTypeEnum.MilestoneReached, "Milestone Reached"),
    ];

    private static readonly (PeriodEnum Code, string Name)[] SubscriptionCycleSeed =
    [
        (PeriodEnum.Daily,   "Daily"),
        (PeriodEnum.Weekly,  "Weekly"),
        (PeriodEnum.Monthly, "Monthly"),
        (PeriodEnum.Yearly,  "Yearly"),
    ];

    private static readonly (string Name, string Icon, string Color)[] SystemCategories =
    [
        ("Food",          "🍔", "#FF6B6B"),
        ("Transport",     "🚗", "#4ECDC4"),
        ("Housing",       "🏠", "#45B7D1"),
        ("Health",        "❤️", "#96CEB4"),
        ("Entertainment", "🎬", "#FFEAA7"),
        ("Shopping",      "🛍️", "#DDA0DD"),
        ("Education",     "📚", "#98D8C8"),
        ("Travel",        "✈️", "#F7DC6F"),
        ("Utilities",     "💡", "#82E0AA"),
        ("Other",         "📦", "#AEB6BF"),
    ];

    private readonly UserManager<User> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly IContext _context;
    private readonly ILogger<DataSeeder> _logger;

    public DataSeeder(
        UserManager<User> userManager,
        RoleManager<IdentityRole> roleManager,
        IContext context,
        ILogger<DataSeeder> logger)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _context = context;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task SeedAsync()
    {
        //await SeedRoleAsync().ConfigureAwait(false);
        //await SeedSuperAdminUserAsync().ConfigureAwait(false);
        await SeedSystemCategoriesAsync().ConfigureAwait(false);
        await SeedBudgetStatusesAsync().ConfigureAwait(false);
        await SeedMilestoneStatusesAsync().ConfigureAwait(false);
        await SeedNotificationTypesAsync().ConfigureAwait(false);
        await SeedSubscriptionCyclesAsync().ConfigureAwait(false);
    }

    private async Task SeedRoleAsync()
    {
        if (await _roleManager.RoleExistsAsync(SuperAdminRole).ConfigureAwait(false))
        {
            _logger.LogInformation("Role '{Role}' already exists — skipping creation.", SuperAdminRole);
            return;
        }

        var result = await _roleManager.CreateAsync(new IdentityRole(SuperAdminRole)).ConfigureAwait(false);

        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            _logger.LogError("Failed to create role '{Role}': {Errors}", SuperAdminRole, errors);
            throw new InvalidOperationException($"Seeding failed — could not create role '{SuperAdminRole}': {errors}");
        }

        _logger.LogInformation("Role '{Role}' created successfully.", SuperAdminRole);
    }

    private async Task SeedSuperAdminUserAsync()
    {
        var existing = await _userManager.FindByEmailAsync(SuperAdminEmail).ConfigureAwait(false);

        if (existing is not null)
        {
            _logger.LogInformation("SuperAdmin user '{Email}' already exists — skipping creation.", SuperAdminEmail);
            return;
        }

        var user = new User
        {
            UserName = SuperAdminUserName,
            Email = SuperAdminEmail,
            EmailConfirmed = true,
            Avatar = string.Empty,
            FirstName = "Super",
            LastName = "Admin",
        };

        var createResult = await _userManager.CreateAsync(user, SuperAdminPassword).ConfigureAwait(false);

        if (!createResult.Succeeded)
        {
            var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
            _logger.LogError("Failed to create SuperAdmin user '{Email}': {Errors}", SuperAdminEmail, errors);
            throw new InvalidOperationException($"Seeding failed — could not create user '{SuperAdminEmail}': {errors}");
        }

        var roleResult = await _userManager.AddToRoleAsync(user, SuperAdminRole).ConfigureAwait(false);

        if (!roleResult.Succeeded)
        {
            var errors = string.Join(", ", roleResult.Errors.Select(e => e.Description));
            _logger.LogError(
                "SuperAdmin user '{Email}' was created but role assignment failed: {Errors}",
                SuperAdminEmail, errors);
            throw new InvalidOperationException(
                $"Seeding failed — user '{SuperAdminEmail}' created but role '{SuperAdminRole}' could not be assigned: {errors}");
        }

        _logger.LogInformation(
            "SuperAdmin user '{Email}' created and assigned role '{Role}' successfully.",
            SuperAdminEmail, SuperAdminRole);
    }

    private async Task SeedSystemCategoriesAsync()
    {
        var existingNames = await _context.Categories
            .Where(c => c.IsSystem)
            .Select(c => c.Name)
            .ToHashSetAsync()
            .ConfigureAwait(false);

        var toInsert = SystemCategories
            .Where(sc => !existingNames.Contains(sc.Name))
            .Select(sc => new Category
            {
                Name = sc.Name,
                Icon = sc.Icon,
                Color = sc.Color,
                IsSystem = true
            })
            .ToList();

        if (toInsert.Count == 0)
        {
            _logger.LogInformation("System categories already exist — skipping creation.");
            return;
        }

        await _context.Categories.AddRangeAsync(toInsert).ConfigureAwait(false);
        await _context.SaveChangesAsync(CancellationToken.None).ConfigureAwait(false);

        _logger.LogInformation("Seeded {Count} system category/categories: {Names}",
            toInsert.Count,
            string.Join(", ", toInsert.Select(c => c.Name)));
    }

    private async Task SeedBudgetStatusesAsync()
    {
        var existingCodes = await _context.BudgetStatuses
            .Select(s => s.Code)
            .ToHashSetAsync()
            .ConfigureAwait(false);

        var toInsert = BudgetStatusSeed
            .Where(s => !existingCodes.Contains(s.Code))
            .Select(s => new BudgetStatus { Title = s.Title, Description = s.Description, Code = s.Code })
            .ToList();

        if (toInsert.Count == 0)
        {
            _logger.LogInformation("Budget statuses already exist — skipping creation.");
            return;
        }

        await _context.BudgetStatuses.AddRangeAsync(toInsert).ConfigureAwait(false);
        await _context.SaveChangesAsync(CancellationToken.None).ConfigureAwait(false);

        _logger.LogInformation("Seeded {Count} budget status(es): {Names}",
            toInsert.Count, string.Join(", ", toInsert.Select(s => s.Title)));
    }

    private async Task SeedMilestoneStatusesAsync()
    {
        var existingCodes = await _context.MilestoneStatuses
            .Select(s => s.Code)
            .ToHashSetAsync()
            .ConfigureAwait(false);

        var toInsert = MilestoneStatusSeed
            .Where(s => !existingCodes.Contains(s.Code))
            .Select(s => new MilestoneStatus { Name = s.Name, Code = s.Code })
            .ToList();

        if (toInsert.Count == 0)
        {
            _logger.LogInformation("Milestone statuses already exist — skipping creation.");
            return;
        }

        await _context.MilestoneStatuses.AddRangeAsync(toInsert).ConfigureAwait(false);
        await _context.SaveChangesAsync(CancellationToken.None).ConfigureAwait(false);

        _logger.LogInformation("Seeded {Count} milestone status(es): {Names}",
            toInsert.Count, string.Join(", ", toInsert.Select(s => s.Name)));
    }

    private async Task SeedNotificationTypesAsync()
    {
        var existingCodes = await _context.NotificationTypes
            .Select(t => t.Code)
            .ToHashSetAsync()
            .ConfigureAwait(false);

        var toInsert = NotificationTypeSeed
            .Where(t => !existingCodes.Contains(t.Code))
            .Select(t => new NotificationType { Name = t.Name, Code = t.Code })
            .ToList();

        if (toInsert.Count == 0)
        {
            _logger.LogInformation("Notification types already exist — skipping creation.");
            return;
        }

        await _context.NotificationTypes.AddRangeAsync(toInsert).ConfigureAwait(false);
        await _context.SaveChangesAsync(CancellationToken.None).ConfigureAwait(false);

        _logger.LogInformation("Seeded {Count} notification type(s): {Names}",
            toInsert.Count, string.Join(", ", toInsert.Select(t => t.Name)));
    }

    private async Task SeedSubscriptionCyclesAsync()
    {
        var existingCodes = await _context.SubscriptionCycles
            .Select(c => c.Code)
            .ToHashSetAsync()
            .ConfigureAwait(false);

        var toInsert = SubscriptionCycleSeed
            .Where(c => !existingCodes.Contains(c.Code))
            .Select(c => new SubscriptionCycle { Name = c.Name, Code = c.Code })
            .ToList();

        if (toInsert.Count == 0)
        {
            _logger.LogInformation("Subscription cycles already exist — skipping creation.");
            return;
        }

        await _context.SubscriptionCycles.AddRangeAsync(toInsert).ConfigureAwait(false);
        await _context.SaveChangesAsync(CancellationToken.None).ConfigureAwait(false);

        _logger.LogInformation("Seeded {Count} subscription cycle(s): {Names}",
            toInsert.Count, string.Join(", ", toInsert.Select(c => c.Name)));
    }
}
