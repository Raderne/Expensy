using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities.Common;
using System.Reflection;

namespace REM.Expensy.Backoffice.Helpers
{
    public static class BaseEntityConfiguration
    {
        private static void ConfigureBaseEntity<TEntity, T>(ModelBuilder modelBuilder)
            where TEntity : BaseEntity<T>
        {
            modelBuilder.Entity<TEntity>(builder =>
            {
                builder.HasKey(e => e.Id);
                builder.Property(e => e.Id).ValueGeneratedOnAdd();

                builder.HasIndex(e => e.Created);
                builder.HasIndex(e => e.CreatedBy);
                builder.HasIndex(e => e.LastModifiedBy);
            });
        }


        public static ModelBuilder ApplyBaseEntityConfiguration(this ModelBuilder modelBuilder)
        {
            var method = typeof(BaseEntityConfiguration).GetTypeInfo().DeclaredMethods
                .Single(m => m.Name == nameof(ConfigureBaseEntity));
            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
                if (entityType.ClrType.IsBaseEntity(out var idType))
                    method.MakeGenericMethod(entityType.ClrType, idType).Invoke(null, [modelBuilder]);

            return modelBuilder;
        }

        private static bool IsBaseEntity(this Type type, out Type? idType)
        {
            for (var baseType = type.BaseType; baseType != null; baseType = baseType.BaseType)
                if (baseType.IsGenericType && baseType.GetGenericTypeDefinition() == typeof(BaseEntity<>))
                {
                    idType = baseType.GetGenericArguments()[0];
                    return true;
                }

            idType = null;
            return false;
        }
    }
}
