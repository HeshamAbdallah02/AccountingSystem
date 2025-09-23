using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AccountingSystem.Controllers;

/// <summary>
/// Weather forecast controller for demonstration purposes
/// </summary>
[ApiController]
[Route("[controller]")]
[SwaggerTag("Weather forecasting operations")]
public class WeatherForecastController : ControllerBase
{
    private static readonly string[] Summaries = new[]
    {
        "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
    };

    private readonly ILogger<WeatherForecastController> _logger;

    /// <summary>
    /// Initializes a new instance of the WeatherForecastController
    /// </summary>
    /// <param name="logger">The logger instance for this controller</param>
    public WeatherForecastController(ILogger<WeatherForecastController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Gets a collection of weather forecasts for the next 5 days
    /// </summary>
    /// <returns>A collection of weather forecast data</returns>
    /// <response code="200">Returns the weather forecast data</response>
    [HttpGet(Name = "GetWeatherForecast")]
    [SwaggerOperation(
        Summary = "Get weather forecast",
        Description = "Retrieves weather forecast data for the next 5 days with random temperature and weather conditions"
    )]
    [SwaggerResponse(200, "Weather forecast data retrieved successfully", typeof(IEnumerable<WeatherForecast>))]
    [SwaggerResponse(500, "Internal server error occurred")]
    public IEnumerable<WeatherForecast> Get()
    {
        return Enumerable.Range(1, 5).Select(index => new WeatherForecast
        {
            Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            TemperatureC = Random.Shared.Next(-20, 55),
            Summary = Summaries[Random.Shared.Next(Summaries.Length)]
        })
        .ToArray();
    }
}
