# AccountingSystem

A comprehensive accounting system built with .NET 8 (LTS), following Clean Architecture principles and best practices.

## Overview

This project provides a robust accounting solution with a clean, maintainable architecture. The system is designed to handle core accounting operations with scalability and testability in mind.

## Architecture

The solution follows Clean Architecture patterns with the following projects:

- **Accounting.Api** - Web API layer providing RESTful endpoints
- **Accounting.Application** - Application layer containing business logic and use cases
- **Accounting.Domain** - Domain layer with entities, value objects, and domain services
- **Accounting.Infrastructure** - Infrastructure layer for data access and external services
- **Accounting.Tests** - Comprehensive test suite

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) (LTS)
- [Git](https://git-scm.com/)

## Getting Started

### Build the Solution

```bash
dotnet build
```

### Run Tests

```bash
dotnet test
```

### Run the Application

```bash
dotnet run --project src/Accounting.Api
```

The API will be available at `https://localhost:5001` (HTTPS) or `http://localhost:5000` (HTTP).

## Development

### Project Structure

```
src/
??? Accounting.Api/          # Web API controllers and configuration
??? Accounting.Application/  # Use cases, DTOs, and application services
??? Accounting.Domain/       # Domain entities, value objects, and interfaces
??? Accounting.Infrastructure/ # Data access, repositories, and external services
??? Accounting.Tests/        # Unit and integration tests
```

### Running in Development Mode

```bash
dotnet watch run --project src/Accounting.Api
```

This will start the application with hot reload enabled for development.

## API Documentation

When running the application, Swagger documentation is available at:
- `https://localhost:5001/swagger` (HTTPS)
- `http://localhost:5000/swagger` (HTTP)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Branching Strategy

- `main` - Stable releases
- `develop` - Ongoing development
- `feature/*` - New features
- `hotfix/*` - Urgent fixes

## License

This project is licensed under the MIT License - see the LICENSE file for details.