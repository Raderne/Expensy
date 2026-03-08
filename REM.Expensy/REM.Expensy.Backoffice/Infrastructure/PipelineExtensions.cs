using REM.Expensy.Backoffice.Infrastructure.Context;
using Serilog;

namespace REM.Expensy.Backoffice.Infrastructure;

public static class PipelineExtensions
{
    public static IApplicationBuilder UseBackofficePipeline(this WebApplication app)
    {
        app.UseSerilogRequestLogging(options =>
        {
            options.MessageTemplate = "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.000} ms";
            options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
            {
                diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
                diagnosticContext.Set("UserAgent", httpContext.Request.Headers.UserAgent.ToString());
                if (httpContext.User.Identity?.IsAuthenticated == true)
                    diagnosticContext.Set("UserId", httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "unknown");
            };
        });

        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI(options => options.SwaggerEndpoint("/swagger/v1/swagger.json", "Expensy Backoffice API v1"));
        }
        else
        {
            // Only redirect to HTTPS in non-Development environments.
            // In Development, mobile clients use HTTP and HTTPS redirect breaks CORS preflight.
            app.UseHttpsRedirection();
        }

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
