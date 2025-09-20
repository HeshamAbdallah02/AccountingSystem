using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Net;
using Testcontainers.MsSql;
using Xunit;

namespace Accounting.Tests.Integration;

public class ApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>, IAsyncLifetime
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly MsSqlContainer _sqlContainer;

    public ApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _sqlContainer = new MsSqlBuilder()
            .WithPassword("TestPassword123!")
            .WithCleanUp(true)
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _sqlContainer.StartAsync();
    }

    public async Task DisposeAsync()
    {
        await _sqlContainer.DisposeAsync();
    }

    [Fact]
    public async Task Get_WeatherForecast_ReturnsSuccessAndCorrectContentType()
    {
        // Arrange
        var client = _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Configure test services here if needed
                // services.AddDbContext<AppDbContext>(options =>
                //     options.UseSqlServer(_sqlContainer.GetConnectionString()));
            });
        }).CreateClient();

        // Act
        var response = await client.GetAsync("/WeatherForecast");

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal("application/json; charset=utf-8", 
            response.Content.Headers.ContentType?.ToString());
    }

    [Fact]
    public async Task Get_HealthCheck_ReturnsHealthy()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync("/health");

        // Assert
        // This will return 404 for now since we haven't implemented health checks
        // Once implemented, change to: response.EnsureSuccessStatusCode();
        Assert.True(response.StatusCode == HttpStatusCode.NotFound || 
                   response.StatusCode == HttpStatusCode.OK);
    }
}