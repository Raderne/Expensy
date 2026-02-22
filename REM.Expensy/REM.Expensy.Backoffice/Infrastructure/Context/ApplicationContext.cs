using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Entities.Common;
using REM.Expensy.Backoffice.Helpers;
using REM.Expensy.Backoffice.Interfaces;
using REM.Expensy.Backoffice.Specifications;
using System.Data;

namespace REM.Expensy.Backoffice.Infrastructure.Context;

public class ApplicationContext : DbContext, IContext
{
    private readonly ILogger<ApplicationContext> _logger;
    private readonly ICurrentUserService _currentUserService;
    private IDbContextTransaction _currentTransaction;

    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<BudgetAlert> BudgetsAlerts => Set<BudgetAlert>();
    public DbSet<BudgetStatus> BudgetStatuses => Set<BudgetStatus>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Draft> Drafts => Set<Draft>();
    public DbSet<Milestone> Milestones => Set<Milestone>();
    public DbSet<MilestoneStatus> MilestoneStatuses => Set<MilestoneStatus>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<NotificationType> NotificationTypes => Set<NotificationType>();
    public DbSet<SavingsGoal> SavingsGoals => Set<SavingsGoal>();
    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<SubscriptionCycle> SubscriptionCycles => Set<SubscriptionCycle>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<User> Users => Set<User>();

    public ApplicationContext(DbContextOptions<ApplicationContext> options, ILogger<ApplicationContext> logger, ICurrentUserService currentUserService) : base(options)
    {
        using var loggerFactory = LoggerFactory.Create(builder =>
        {
            builder.AddFilter("System", LogLevel.Warning)
                   .AddFilter("Microsoft", LogLevel.Warning)
                   .AddFilter("REM.Expensy.Backoffice", LogLevel.Debug)
                   .AddConsole();
        });
        _logger = loggerFactory.CreateLogger<ApplicationContext>();
        _currentUserService = currentUserService;
    }

    public IQueryable<TEntity> ApplySpecification<TEntity>(ISpecification<TEntity> spec) where TEntity : class
    {
        return SpecificationEvaluator<TEntity>.GetQuery(Set<TEntity>().AsNoTracking(), spec);
    }

    private void AddDeletedQueryFilter<TEntity>(ModelBuilder builder) where TEntity : class, IDeletableEntity
    {
        builder.Entity<TEntity>().HasQueryFilter(b => !(b.IsDeleted ?? false));
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.ApplyBaseEntityConfiguration();
        builder.ApplyConfigurationsFromAssembly(typeof(ApplicationContext).Assembly);

        foreach (var entity in builder.Model.GetEntityTypes()
            .Where(e => typeof(IDeletableEntity).IsAssignableFrom(e.ClrType)))
        {
            ReflectionHelper.InvokeGenericMethod(typeof(ApplicationContext), this, nameof(AddDeletedQueryFilter),
                new Type[] { entity.ClrType }, builder);
        }

        CreateContextInitializer(builder).Seed();
    }

    protected IContextInitializer CreateContextInitializer(ModelBuilder builder)
    {
        return new ApplicationContextInitializer(builder);
    }

    public async Task BeginTransactionAsync()
    {
        if (_currentTransaction != null) return;

        _currentTransaction = await base.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted)
            .ConfigureAwait(false);
    }

    public async Task CommitTransactionAsync(CancellationToken cancellationToken = default, string TenantId = null)
    {
        try
        {
            await SaveChangesAsync(null, cancellationToken, TenantId).ConfigureAwait(false);
            _currentTransaction?.Commit();
        }
        catch
        {
            RollbackTransaction();
            throw;
        }
        finally
        {
            if (_currentTransaction != null)
            {
                _currentTransaction.Dispose();
                _currentTransaction = null;
            }
        }
    }

    public void RollbackTransaction()
    {
        try
        {
            _currentTransaction?.Rollback();
        }
        finally
        {
            if (_currentTransaction != null)
            {
                _currentTransaction.Dispose();
                _currentTransaction = null;
            }
        }
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return SaveChangesAsync(null, cancellationToken);
    }

    public virtual async Task<int> SaveChangesAsync(Action<Exception>? onException = null, CancellationToken cancellationToken = default, string tenantId = null)
    {
        string userId = null;
        if (_currentUserService.IsLoggedIn())
        {
            userId = _currentUserService.UserId;
        }

        // Apply auditing 
        foreach (var entry in ChangeTracker.Entries<IAuditableEntity<string>>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedBy = userId;
                    entry.Entity.Created = DateTime.UtcNow;
                    entry.Entity.LastModifiedBy = userId;
                    entry.Entity.LastModified = DateTime.UtcNow;
                    break;
                case EntityState.Modified:
                    entry.Entity.LastModifiedBy = userId;
                    entry.Entity.LastModified = DateTime.UtcNow;
                    break;
            }
        }

        var result = 0;
        try
        {
            result = await base.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex)
        {
            if (onException != null)
            {
                onException(ex);
            }
            else
            {
                throw new ApplicationException($"Error While Saving Data: {ex.Message}");
            }
        }

        return result;
    }
}
