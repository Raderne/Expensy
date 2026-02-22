using REM.Expensy.Backoffice.Infrastructure.Context;
using Serilog;

namespace REM.Expensy.Backoffice.Infrastructure;

public static class PipelineExtensions
{
    public static IApplicationBuilder UseBackofficePipeline(this WebApplication app)
    {
        app.UseSerilogRequestLogging();

        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI(options => options.SwaggerEndpoint("/swagger/v1/swagger.json", "Expensy Backoffice API v1"));
        }

        app.UseHttpsRedirection();

        var policyName = app.Configuration.GetSection("Cors")["PolicyName"] ?? "ExpensyCors";
        app.UseCors(policyName);
        app.UseAuthentication();
        app.UseAuthorization();
        app.MapControllers();

        var connectionString = app.Configuration.GetConnectionString(nameof(ApplicationContext));
        if (!string.IsNullOrEmpty(connectionString))
            app.MapHealthChecks("/health");

        return app;
    }
}
