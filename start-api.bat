@echo off
echo Starting Accounting API...
echo.
echo HTTPS URL: https://localhost:7111/swagger
echo HTTP URL:  http://localhost:5212/swagger
echo.
echo Press Ctrl+C to stop the application
echo.

cd /d "%~dp0src\Accounting.Api"
dotnet run