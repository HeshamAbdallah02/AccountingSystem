#Requires -Version 5.1

<#
.SYNOPSIS
    Fixes local HTTPS certificate issues for ASP.NET Core development with Kestrel

.DESCRIPTION
    This script resolves NET::ERR_CERT_INVALID browser errors when running ASP.NET Core
    applications locally with 'dotnet run'. It manages development certificates,
    ensures proper trust configuration, and provides fallback options including mkcert.

.NOTES
    Author: GitHub Copilot
    Version: 1.0
    Requires: Administrator privileges, .NET SDK
#>

[CmdletBinding()]
param()

# Script configuration
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Color output functions
function Write-Success { param($Message) Write-Host "? $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "??  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "? $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "??  $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "?? $Message" -ForegroundColor Blue }
function Write-Header { param($Message) Write-Host "`n" + "="*80 -ForegroundColor Magenta; Write-Host "   $Message" -ForegroundColor Magenta; Write-Host "="*80 -ForegroundColor Magenta }

function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DotNetInstalled {
    try {
        $dotnetVersion = & dotnet --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success ".NET SDK found (version: $dotnetVersion)"
            return $true
        }
    }
    catch {
        Write-Error ".NET SDK not found. Please install .NET 8 SDK from https://dotnet.microsoft.com/download"
        return $false
    }
    return $false
}

function Invoke-DevCertCheck {
    Write-Step "Checking existing development certificates..."
    
    try {
        $checkOutput = & dotnet dev-certs https --check 2>&1
        $checkExitCode = $LASTEXITCODE
        
        Write-Info "Certificate check output:"
        Write-Host $checkOutput -ForegroundColor Gray
        
        if ($checkExitCode -eq 0) {
            Write-Success "Valid HTTPS development certificate found!"
            return $true
        } else {
            Write-Warning "No valid HTTPS development certificate found."
            return $false
        }
    }
    catch {
        Write-Error "Failed to check development certificates: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-DevCertCleanAndTrust {
    Write-Step "Cleaning existing certificates..."
    
    try {
        $cleanOutput = & dotnet dev-certs https --clean 2>&1
        Write-Info "Clean output: $cleanOutput"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Certificates cleaned successfully"
        } else {
            Write-Warning "Certificate cleaning had issues, but continuing..."
        }
    }
    catch {
        Write-Warning "Certificate cleaning failed: $($_.Exception.Message)"
    }
    
    Write-Step "Creating and trusting new development certificate..."
    Write-Info "This will show a Windows security dialog - please click 'Yes' to trust the certificate."
    
    try {
        $trustOutput = & dotnet dev-certs https --trust 2>&1
        $trustExitCode = $LASTEXITCODE
        
        Write-Info "Trust output:"
        Write-Host $trustOutput -ForegroundColor Gray
        
        if ($trustExitCode -eq 0) {
            Write-Success "Certificate created and trusted successfully!"
            return $true
        } else {
            Write-Warning "Certificate trust operation failed or was cancelled."
            return $false
        }
    }
    catch {
        Write-Error "Failed to create/trust certificate: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-ManualCertificateImport {
    Write-Step "Attempting manual certificate import as fallback..."
    
    $pfxPath = "$env:USERPROFILE\aspnetcore_localhost.pfx"
    $pfxPassword = "P@ssw0rd!"
    
    try {
        # Export certificate to PFX
        Write-Info "Exporting certificate to PFX..."
        $exportOutput = & dotnet dev-certs https -ep $pfxPath -p $pfxPassword 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Certificate exported to: $pfxPath"
            
            # Import to Trusted Root store
            Write-Info "Importing certificate to Trusted Root Certification Authorities..."
            $securePassword = ConvertTo-SecureString $pfxPassword -AsPlainText -Force
            $importResult = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\Root -Password $securePassword
            
            if ($importResult) {
                Write-Success "Certificate imported successfully!"
                Write-Info "Imported certificate thumbprint: $($importResult.Thumbprint)"
                
                # Clean up PFX file
                Remove-Item $pfxPath -Force -ErrorAction SilentlyContinue
                Write-Info "Temporary PFX file removed."
                
                return $true
            } else {
                Write-Error "Failed to import certificate to Trusted Root store."
                return $false
            }
        } else {
            Write-Error "Failed to export certificate to PFX."
            Write-Info "Export output: $exportOutput"
            return $false
        }
    }
    catch {
        Write-Error "Manual certificate import failed: $($_.Exception.Message)"
        return $false
    }
}

function Show-CertificateListings {
    Write-Header "Current Certificate Status"
    
    Write-Info "Personal certificates (Cert:\CurrentUser\My):"
    try {
        $personalCerts = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*localhost*" } | Select-Object Subject, Thumbprint, NotAfter
        if ($personalCerts) {
            $personalCerts | Format-Table -AutoSize
        } else {
            Write-Warning "No localhost certificates found in Personal store."
        }
    }
    catch {
        Write-Error "Failed to list personal certificates: $($_.Exception.Message)"
    }
    
    Write-Info "Trusted Root certificates (Cert:\CurrentUser\Root):"
    try {
        $rootCerts = Get-ChildItem Cert:\CurrentUser\Root | Where-Object { $_.Subject -like "*localhost*" } | Select-Object Subject, Thumbprint, NotAfter
        if ($rootCerts) {
            $rootCerts | Format-Table -AutoSize
        } else {
            Write-Warning "No localhost certificates found in Trusted Root store."
        }
    }
    catch {
        Write-Error "Failed to list root certificates: $($_.Exception.Message)"
    }
}

function Test-MkcertInstalled {
    try {
        $mkcertVersion = & mkcert -version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "mkcert found: $mkcertVersion"
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

function Show-MkcertInstructions {
    Write-Header "Alternative Solution: mkcert"
    
    if (Test-MkcertInstalled) {
        Write-Success "mkcert is already installed!"
        Write-Info "To use mkcert for local HTTPS:"
        Write-Host "1. Install CA: " -NoNewline; Write-Host "mkcert -install" -ForegroundColor Yellow
        Write-Host "2. Generate cert: " -NoNewline; Write-Host "mkcert localhost 127.0.0.1 ::1" -ForegroundColor Yellow
        Write-Info "3. Configure Kestrel in Program.cs:"
        
        Write-Host @"
builder.WebHost.ConfigureKestrel(options =>
{
    options.ConfigureHttpsDefaults(httpsOptions =>
    {
        httpsOptions.ServerCertificate = new X509Certificate2("localhost+2.pem", "localhost+2-key.pem");
    });
});
"@ -ForegroundColor Gray
    } else {
        Write-Info "mkcert is not installed. To install it:"
        Write-Host "Using Chocolatey: " -NoNewline; Write-Host "choco install mkcert" -ForegroundColor Yellow
        Write-Host "Using Scoop: " -NoNewline; Write-Host "scoop install mkcert" -ForegroundColor Yellow
        Write-Info "After installation, run this script again or use the commands shown above."
    }
}

function Get-LaunchSettingsPort {
    $launchSettingsPath = "src\Accounting.Api\Properties\launchSettings.json"
    
    if (Test-Path $launchSettingsPath) {
        try {
            $launchSettings = Get-Content $launchSettingsPath | ConvertFrom-Json
            $httpsPort = $launchSettings.profiles.'https'.applicationUrl -replace 'https://localhost:', ''
            if ($httpsPort) {
                return $httpsPort
            }
        }
        catch {
            Write-Warning "Could not parse launchSettings.json"
        }
    }
    
    return "5001" # Default HTTPS port
}

function Show-FinalVerificationSteps {
    Write-Header "Final Verification Steps"
    
    $port = Get-LaunchSettingsPort
    
    Write-Info "1. Restart your browser completely (close all windows)"
    Write-Info "2. Run your application:"
    Write-Host "   dotnet run --project src\Accounting.Api" -ForegroundColor Yellow
    Write-Info "3. Open your application:"
    Write-Host "   https://localhost:$port/swagger" -ForegroundColor Yellow
    
    Write-Info "`nIf you still see certificate errors:"
    Write-Info "• Check certificate in browser: Click lock icon ? Certificate ? Details"
    Write-Info "• Clear HSTS settings: Open chrome://net-internals/#hsts"
    Write-Info "  - In 'Delete domain security policies', enter: localhost"
    Write-Info "  - Click 'Delete'"
    Write-Info "• Try incognito/private browsing mode"
    Write-Info "• Restart browser and try again"
    
    Write-Info "`nFor Edge browser:"
    Write-Info "• Go to edge://net-internals/#hsts for HSTS settings"
    
    Write-Info "`nFor Firefox:"
    Write-Info "• Clear security exceptions in Settings ? Privacy & Security ? Certificates ? View Certificates ? Servers"
}

# Main script execution
function main {
    Write-Header "ASP.NET Core Local HTTPS Certificate Fix"
    
    # Check if running as Administrator
    if (-not (Test-IsAdministrator)) {
        Write-Error "This script must be run as Administrator!"
        Write-Info "Please right-click PowerShell and select 'Run as Administrator', then run:"
        Write-Host "powershell -ExecutionPolicy Bypass -File .\fix-local-https.ps1" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Success "Running as Administrator ?"
    
    # Check .NET installation
    if (-not (Test-DotNetInstalled)) {
        exit 1
    }
    
    # Initial certificate check
    $initialCheckPassed = Invoke-DevCertCheck
    
    if (-not $initialCheckPassed) {
        # Try standard clean and trust approach
        $trustSucceeded = Invoke-DevCertCleanAndTrust
        
        if (-not $trustSucceeded) {
            Write-Warning "Standard certificate trust failed. Trying manual import..."
            $manualImportSucceeded = Invoke-ManualCertificateImport
            
            if (-not $manualImportSucceeded) {
                Write-Warning "Manual certificate import also failed."
            }
        }
        
        # Re-check certificates after our attempts
        Write-Step "Re-checking certificates after fixes..."
        $finalCheckPassed = Invoke-DevCertCheck
        
        if (-not $finalCheckPassed) {
            Write-Warning "Standard .NET dev-certs approach did not work."
            Show-MkcertInstructions
        } else {
            Write-Success "Certificate issues have been resolved!"
        }
    }
    
    # Show current certificate status
    Show-CertificateListings
    
    # Show verification steps
    Show-FinalVerificationSteps
    
    Write-Header "Script Completed"
    Write-Info "If issues persist, try the mkcert alternative or check browser-specific settings."
}

# Execute main function
main