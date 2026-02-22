using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Infrastructure.Context
{
    public class ApplicationContextInitializer : IContextInitializer
    {
        private readonly ModelBuilder _modelBuilder;

        public ApplicationContextInitializer(ModelBuilder modelBuilder)
        {
            _modelBuilder = modelBuilder;
        }

        public void Seed()
        {
            // Seed initial data here if needed

        }
    }
}
