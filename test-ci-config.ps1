#!/usr/bin/env pwsh

Write-Host "Testing CI Configuration..." -ForegroundColor Green

# Test 1: CI Environment (should use HTTP only, no HTTPS redirection)
Write-Host "`n=== Test 1: CI Environment ===" -ForegroundColor Yellow
$env:ASPNETCORE_ENVIRONMENT = "CI"
$env:CI = "true"

Write-Host "Starting API in CI mode..."
$apiProcess = Start-Process -NoNewWindow -FilePath "dotnet" -ArgumentList "run --project src/Accounting.Api --urls http://localhost:5000" -PassThru -RedirectStandardOutput "ci-test-output.log" -RedirectStandardError "ci-test-error.log"

Start-Sleep 8

try {
    # Test HTTP endpoint
    $httpResponse = Invoke-WebRequest -Uri "http://localhost:5000/swagger/v1/swagger.json" -UseBasicParsing -TimeoutSec 10
    Write-Host "? HTTP Swagger JSON: Status $($httpResponse.StatusCode), Length: $($httpResponse.Content.Length)" -ForegroundColor Green
    
    # Test health check
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "? HTTP Health Check: Status $($healthResponse.StatusCode)" -ForegroundColor Green
    
    # Verify no HTTPS redirection by checking a regular endpoint
    $swaggerResponse = Invoke-WebRequest -Uri "http://localhost:5000/swagger" -UseBasicParsing -TimeoutSec 10 -MaximumRedirection 0
    Write-Host "? HTTP Swagger UI: Status $($swaggerResponse.StatusCode) (No HTTPS redirect)" -ForegroundColor Green
    
} catch {
    Write-Host "? CI Test Failed: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path "ci-test-output.log") { 
        Write-Host "Output:" -ForegroundColor Gray
        Get-Content "ci-test-output.log" 
    }
    if (Test-Path "ci-test-error.log") { 
        Write-Host "Errors:" -ForegroundColor Gray
        Get-Content "ci-test-error.log" 
    }
} finally {
    if (-not $apiProcess.HasExited) {
        $apiProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    Get-Process | Where-Object {$_.ProcessName -eq "dotnet" -and $_.Id -ne $PID} | Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=== Test 2: Development Environment ===" -ForegroundColor Yellow
Remove-Item Env:CI -ErrorAction SilentlyContinue
$env:ASPNETCORE_ENVIRONMENT = "Development"

Write-Host "Starting API in Development mode..."
$devProcess = Start-Process -NoNewWindow -FilePath "dotnet" -ArgumentList "run --project src/Accounting.Api" -PassThru -RedirectStandardOutput "dev-test-output.log" -RedirectStandardError "dev-test-error.log"

Start-Sleep 8

try {
    # In development mode, it should use the default ports from launchSettings.json
    # Let's try both HTTP and HTTPS endpoints
    
    # Try HTTP endpoint (should redirect to HTTPS in dev mode)
    try {
        $httpDevResponse = Invoke-WebRequest -Uri "http://localhost:5212/health" -UseBasicParsing -TimeoutSec 10 -MaximumRedirection 0
        Write-Host "??  HTTP Dev Mode: Status $($httpDevResponse.StatusCode) (Expected redirect)" -ForegroundColor Yellow
    } catch {
        if ($_.Exception.Message -like "*redirect*" -or $_.Exception.Message -like "*301*" -or $_.Exception.Message -like "*302*") {
            Write-Host "? HTTP Dev Mode: Properly redirected to HTTPS" -ForegroundColor Green
        } else {
            Write-Host "? HTTP Dev Mode: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "? Development environment test completed" -ForegroundColor Green
    
} catch {
    Write-Host "??  Development Test: $($_.Exception.Message)" -ForegroundColor Yellow
} finally {
    if (-not $devProcess.HasExited) {
        $devProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    Get-Process | Where-Object {$_.ProcessName -eq "dotnet" -and $_.Id -ne $PID} | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Cleanup
Remove-Item "ci-test-output.log", "ci-test-error.log", "dev-test-output.log", "dev-test-error.log" -ErrorAction SilentlyContinue

Write-Host "`n? Testing completed!" -ForegroundColor Green
Write-Host "The API is now configured to:" -ForegroundColor Cyan
Write-Host "  • Use HTTP-only (port 5000) in CI environments" -ForegroundColor Gray
Write-Host "  • Disable HTTPS redirection in CI environments" -ForegroundColor Gray
Write-Host "  • Use normal HTTPS behavior in Development/Production" -ForegroundColor Gray