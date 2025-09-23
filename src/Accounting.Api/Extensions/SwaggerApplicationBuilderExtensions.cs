namespace AccountingSystem.Extensions;

/// <summary>
/// Extension methods for configuring Swagger/OpenAPI middleware in the request pipeline
/// </summary>
public static class SwaggerApplicationBuilderExtensions
{
    /// <summary>
    /// Configures Swagger middleware and UI
    /// </summary>
    /// <param name="app">The application builder</param>
    /// <param name="env">The web host environment</param>
    /// <param name="allowInNonDev">Allow Swagger in non-development environments</param>
    /// <returns>The application builder for chaining</returns>
    public static IApplicationBuilder UseSwaggerWithUI(this IApplicationBuilder app, IWebHostEnvironment env, bool allowInNonDev = false)
    {
        if (env.IsDevelopment() || allowInNonDev)
        {
            app.UseSwagger();
            app.UseSwaggerUI(options =>
            {
                options.SwaggerEndpoint("/swagger/v1/swagger.json", "Accounting System API v1");
                options.RoutePrefix = "swagger";
                options.DisplayRequestDuration();
                options.EnableDeepLinking();
                options.EnableFilter();
                options.ShowExtensions();
                options.EnableValidator();
            });
        }

        return app;
    }
}