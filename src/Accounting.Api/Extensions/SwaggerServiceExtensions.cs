using Microsoft.OpenApi.Models;
using System.Reflection;

namespace AccountingSystem.Extensions;

/// <summary>
/// Extension methods for configuring Swagger/OpenAPI services in the DI container
/// </summary>
public static class SwaggerServiceExtensions
{
    /// <summary>
    /// Adds Swagger/OpenAPI services with JWT Bearer authentication support
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <param name="config">Configuration instance</param>
    /// <param name="allowInNonDev">Allow Swagger in non-development environments</param>
    /// <returns>The service collection for chaining</returns>
    public static IServiceCollection AddSwaggerWithAuth(this IServiceCollection services, IConfiguration config, bool allowInNonDev = false)
    {
        services.AddEndpointsApiExplorer();
        
        services.AddSwaggerGen(options =>
        {
            options.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "Accounting System API",
                Version = "v1",
                Description = "A comprehensive accounting system API built with Clean Architecture principles",
                Contact = new OpenApiContact
                {
                    Name = "Accounting System Team",
                    Email = "support@accountingsystem.com"
                }
            });

            // Enable annotations
            options.EnableAnnotations();

            // Include XML comments
            var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
            var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
            if (File.Exists(xmlPath))
            {
                options.IncludeXmlComments(xmlPath);
            }

            // Add JWT Bearer authentication
            options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Name = "Authorization",
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                In = ParameterLocation.Header,
                Description = "Enter 'Bearer' followed by a space and your JWT token"
            });

            options.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference = new OpenApiReference
                        {
                            Type = ReferenceType.SecurityScheme,
                            Id = "Bearer"
                        }
                    },
                    Array.Empty<string>()
                }
            });
        });

        return services;
    }
}