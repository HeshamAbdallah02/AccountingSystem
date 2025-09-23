namespace AccountingSystem;

/// <summary>
/// Represents weather forecast data for a specific date
/// </summary>
public class WeatherForecast
{
    /// <summary>
    /// Gets or sets the date for this weather forecast
    /// </summary>
    public DateOnly Date { get; set; }

    /// <summary>
    /// Gets or sets the temperature in Celsius
    /// </summary>
    public int TemperatureC { get; set; }

    /// <summary>
    /// Gets the temperature in Fahrenheit (calculated from Celsius)
    /// </summary>
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);

    /// <summary>
    /// Gets or sets a summary description of the weather conditions
    /// </summary>
    public string? Summary { get; set; }
}
