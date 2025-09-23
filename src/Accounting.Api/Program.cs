using AccountingSystem.Extensions;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

// Add Swagger with authentication support
builder.Services.AddSwaggerWithAuth(builder.Configuration);

// Add health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy("API is running"));

// Configure Kestrel for CI environments
var environment = builder.Environment.EnvironmentName;
var isCIEnvironment = environment.Equals("CI", StringComparison.OrdinalIgnoreCase) || 
                     !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("CI")) ||
                     !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("GITHUB_ACTIONS"));

if (isCIEnvironment)
{
    // In CI environments, configure to use HTTP only on port 5000
    builder.WebHost.UseUrls("http://localhost:5000");
}

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseSwaggerWithUI(app.Environment);

// Only use HTTPS redirection if not in CI environment
if (!isCIEnvironment)
{
    app.UseHttpsRedirection();
}

app.UseAuthorization();

app.MapControllers();

// Map health check endpoints
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
app.MapHealthChecks("/health/live", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = _ => false
});

app.Run();

/// <summary>
/// Main program class for the Accounting API application
/// </summary>
public partial class Program { }
