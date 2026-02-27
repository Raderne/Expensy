using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using REM.Expensy.Backoffice.Entities;

namespace REM.Expensy.Backoffice.Interfaces;

public interface IReadOnlyContext
{
    IQueryable<TEntity> ApplySpecification<TEntity>(ISpecification<TEntity> spec) where TEntity : class;

    DbSet<TEntity> Set<TEntity>() where TEntity : class;
    EntityEntry Entry(object entity);

    public DbSet<Budget> Budgets { get; }
    public DbSet<BudgetAlert> BudgetsAlerts { get; }
    public DbSet<BudgetStatus> BudgetStatuses { get; }
    public DbSet<Category> Categories { get; }
    public DbSet<Draft> Drafts { get; }
    public DbSet<Milestone> Milestones { get; }
    public DbSet<MilestoneStatus> MilestoneStatuses { get; }
    public DbSet<Notification> Notifications { get; }
    public DbSet<NotificationType> NotificationTypes { get; }
    public DbSet<SavingsGoal> SavingsGoals { get; }
    public DbSet<Subscription> Subscriptions { get; }
    public DbSet<SubscriptionCycle> SubscriptionCycles { get; }
    public DbSet<Transaction> Transactions { get; }
    public DbSet<Wallet> Wallets { get; }
    public DbSet<User> Users { get; }
    public DbSet<RefreshToken> RefreshTokens { get; }
}