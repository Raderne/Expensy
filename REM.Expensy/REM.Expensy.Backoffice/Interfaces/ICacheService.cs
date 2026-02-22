using REM.Expensy.Backoffice.Entities.Common;

namespace REM.Expensy.Backoffice.Interfaces
{
    public interface ICacheService
    {
        T? Get<T>(int id) where T : IdBasedEntity<int>;
        T? Get<T>(string key) where T : class;
        void Refresh(string key);
        void Refresh<T>(int id) where T : IdBasedEntity<int>;
        void Remove(string key);
        void Remove<T>(int id) where T : IdBasedEntity<int>;
        void Set(string key, object? value);
        void Set<T>(T? value) where T : IdBasedEntity<int>;
    }
}
