# Use the official .NET 8 runtime as base image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Use the official .NET 8 SDK for building
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy project files
COPY ["src/Accounting.Api/Accounting.Api.csproj", "src/Accounting.Api/"]
COPY ["src/Accounting.Application/Accounting.Application.csproj", "src/Accounting.Application/"]
COPY ["src/Accounting.Domain/Accounting.Domain.csproj", "src/Accounting.Domain/"]
COPY ["src/Accounting.Infrastructure/Accounting.Infrastructure.csproj", "src/Accounting.Infrastructure/"]

# Restore dependencies
RUN dotnet restore "src/Accounting.Api/Accounting.Api.csproj"

# Copy all source code
COPY . .

# Build the application
WORKDIR "/src/src/Accounting.Api"
RUN dotnet build "Accounting.Api.csproj" -c $BUILD_CONFIGURATION -o /app/build

# Publish the application
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "Accounting.Api.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Final stage/image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Create a non-root user
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["dotnet", "Accounting.Api.dll"]