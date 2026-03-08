using Microsoft.AspNetCore.Identity;
using REM.Expensy.Backoffice.Entities;

namespace REM.Expensy.Backoffice.Infrastructure.Services;

/// <summary>
/// Idempotent startup seeder that ensures the SuperAdmin role and user exist.
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

    private readonly UserManager<User> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly ILogger<DataSeeder> _logger;

    public DataSeeder(
        UserManager<User> userManager,
        RoleManager<IdentityRole> roleManager,
        ILogger<DataSeeder> logger)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task SeedAsync()
    {
        await SeedRoleAsync().ConfigureAwait(false);
        await SeedSuperAdminUserAsync().ConfigureAwait(false);
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
            Avatar = string.Empty
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
}
