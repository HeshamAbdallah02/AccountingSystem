#Requires -Version 5.1

<#
.SYNOPSIS
    Migrates a single ASP.NET project to Clean Architecture structure under src/

.DESCRIPTION
    This script automates the migration of an existing AccountingSystem project to a 
    Clean Architecture structure with proper project separation and references.
    
    The script creates a new git branch, backs up the original project, and creates
    new projects under src/ following Clean Architecture patterns.

.PARAMETER BranchName
    The name of the git branch to create for this migration

.EXAMPLE
    .\migrate-to-src.ps1
    
    Runs the migration interactively, prompting for branch name and confirmation steps.

.NOTES
    Author: GitHub Copilot
    Version: 1.0
    Requires: .NET 8 SDK, Git (optional but recommended)
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Git branch name for this migration")]
    [string]$BranchName
)

# Script configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Color output functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "🔄 $Message" -ForegroundColor Blue }

# Project structure configuration
$SourceFolder = "src"
$OriginalProjectFolder = "AccountingSystem"
$SolutionFile = "AccountingSystem.sln"
$BackupFolder = "AccountingSystem_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

$NewProjects = @{
    "Accounting.Api" = "webapi"
    "Accounting.Application" = "classlib"
    "Accounting.Domain" = "classlib"
    "Accounting.Infrastructure" = "classlib"
    "Accounting.Tests" = "xunit"
}

$ProjectReferences = @(
    @{ From = "Accounting.Application"; To = "Accounting.Domain" }
    @{ From = "Accounting.Infrastructure"; To = "Accounting.Domain" }
    @{ From = "Accounting.Infrastructure"; To = "Accounting.Application" }
    @{ From = "Accounting.Api"; To = "Accounting.Application" }
)

$RecommendedPackages = @(
    "Microsoft.EntityFrameworkCore.SqlServer",
    "Microsoft.AspNetCore.Authentication.JwtBearer",
    "Swashbuckle.AspNetCore"
)

function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    # Check if solution file exists
    if (-not (Test-Path $SolutionFile)) {
        Write-Error "Solution file '$SolutionFile' not found in current directory."
        Write-Info "Please run this script from the repository root where the .sln file is located."
        return $false
    }
    
    # Check if original project folder exists
    if (-not (Test-Path $OriginalProjectFolder)) {
        Write-Error "Original project folder '$OriginalProjectFolder' not found."
        return $false
    }
    
    # Check if .NET CLI is available
    try {
        $dotnetVersion = & dotnet --version 2>$null
        Write-Success ".NET CLI found (version: $dotnetVersion)"
    }
    catch {
        Write-Error ".NET CLI not found. Please install .NET 8 SDK."
        return $false
    }
    
    # Check if git is available (optional)
    try {
        $gitVersion = & git --version 2>$null
        Write-Success "Git found ($gitVersion)"
        $script:GitAvailable = $true
    }
    catch {
        Write-Warning "Git not found. File moves will use PowerShell copy instead of git mv."
        $script:GitAvailable = $false
    }
    
    Write-Success "Prerequisites check completed."
    return $true
}

function Confirm-Action {
    param(
        [string]$Message,
        [string]$DefaultChoice = "Y"
    )
    
    $choices = if ($DefaultChoice -eq "Y") { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Message $choices"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultChoice -eq "Y"
    }
    
    return $response -match "^[Yy]"
}

function New-GitBranch {
    if (-not $script:GitAvailable) {
        Write-Warning "Git not available, skipping branch creation."
        return
    }
    
    try {
        # Check if we're in a git repository
        & git status *>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Not in a git repository, skipping branch creation."
            return
        }
        
        if ([string]::IsNullOrWhiteSpace($BranchName)) {
            $BranchName = Read-Host "Enter git branch name for this migration (or press Enter to skip)"
        }
        
        if ([string]::IsNullOrWhiteSpace($BranchName)) {
            Write-Info "Skipping git branch creation."
            return
        }
        
        Write-Step "Creating git branch '$BranchName'..."
        & git checkout -b $BranchName
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created and switched to branch '$BranchName'"
        } else {
            Write-Warning "Failed to create branch. Continuing without branch creation."
        }
    }
    catch {
        Write-Warning "Git operation failed: $($_.Exception.Message)"
    }
}

function New-BackupCopy {
    Write-Step "Creating backup of original project..."
    
    if (Test-Path $BackupFolder) {
        Write-Warning "Backup folder '$BackupFolder' already exists."
        if (-not (Confirm-Action "Overwrite existing backup?")) {
            Write-Error "Cannot proceed without backup. Please remove existing backup or choose different name."
            exit 1
        }
        Remove-Item $BackupFolder -Recurse -Force
    }
    
    try {
        Copy-Item $OriginalProjectFolder $BackupFolder -Recurse
        Write-Success "Backup created at '$BackupFolder'"
    }
    catch {
        Write-Error "Failed to create backup: $($_.Exception.Message)"
        exit 1
    }
}

function New-SourceStructure {
    Write-Step "Creating source directory structure..."
    
    # Create src folder if it doesn't exist
    if (-not (Test-Path $SourceFolder)) {
        New-Item -ItemType Directory -Path $SourceFolder | Out-Null
        Write-Success "Created '$SourceFolder' directory"
    }
    
    # Create new projects
    foreach ($project in $NewProjects.GetEnumerator()) {
        $projectPath = Join-Path $SourceFolder $project.Key
        $projectType = $project.Value
        
        Write-Step "Creating $projectType project: $($project.Key)..."
        
        try {
            & dotnet new $projectType -n $project.Key -o $projectPath --force
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Created project: $($project.Key)"
            } else {
                Write-Error "Failed to create project: $($project.Key)"
                throw "dotnet new failed"
            }
        }
        catch {
            Write-Error "Failed to create project $($project.Key): $($_.Exception.Message)"
            Write-Info "You may need to create this project manually using: dotnet new $projectType -n $($project.Key) -o $projectPath"
        }
    }
}

function Add-ProjectsToSolution {
    Write-Step "Adding new projects to solution..."
    
    foreach ($project in $NewProjects.Keys) {
        $projectPath = Join-Path $SourceFolder "$project\$project.csproj"
        
        try {
            Write-Info "Adding $project to solution..."
            & dotnet sln $SolutionFile add $projectPath
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Added $project to solution"
            } else {
                Write-Warning "Failed to add $project to solution"
            }
        }
        catch {
            Write-Warning "Failed to add $project to solution: $($_.Exception.Message)"
        }
    }
}

function Move-ProjectFiles {
    Write-Step "Moving files from original project to Accounting.Api..."
    
    $apiProjectPath = Join-Path $SourceFolder "Accounting.Api"
    $filesToMove = @()
    
    # Define files to move
    $criticalFiles = @(
        "Program.cs",
        "appsettings.json",
        "appsettings.Development.json",
        "appsettings.Production.json",
        "WeatherForecast.cs"
    )
    
    # Check for Controllers directory
    $controllersSource = Join-Path $OriginalProjectFolder "Controllers"
    $controllersTarget = Join-Path $apiProjectPath "Controllers"
    
    # Check for Properties directory (launchSettings.json)
    $propertiesSource = Join-Path $OriginalProjectFolder "Properties"
    $propertiesTarget = Join-Path $apiProjectPath "Properties"
    
    # Move critical files
    foreach ($file in $criticalFiles) {
        $sourcePath = Join-Path $OriginalProjectFolder $file
        if (Test-Path $sourcePath) {
            $filesToMove += @{ Source = $sourcePath; Target = Join-Path $apiProjectPath $file }
        }
    }
    
    # Move Controllers directory
    if (Test-Path $controllersSource) {
        # Remove default controller from new project if it exists
        $defaultController = Join-Path $controllersTarget "WeatherForecastController.cs"
        if (Test-Path $defaultController) {
            Remove-Item $defaultController -Force
        }
        $filesToMove += @{ Source = $controllersSource; Target = $controllersTarget; IsDirectory = $true }
    }
    
    # Move Properties directory
    if (Test-Path $propertiesSource) {
        $filesToMove += @{ Source = $propertiesSource; Target = $propertiesTarget; IsDirectory = $true }
    }
    
    # Display files to be moved
    Write-Info "Files/directories to be moved:"
    foreach ($item in $filesToMove) {
        $type = if ($item.IsDirectory) { "Directory" } else { "File" }
        Write-Host "  $type`: $($item.Source) -> $($item.Target)" -ForegroundColor Gray
    }
    
    if (-not (Confirm-Action "Proceed with moving these files?")) {
        Write-Warning "File move cancelled by user."
        return
    }
    
    # Perform the moves
    foreach ($item in $filesToMove) {
        try {
            $sourceExists = Test-Path $item.Source
            if (-not $sourceExists) {
                Write-Warning "Source not found, skipping: $($item.Source)"
                continue
            }
            
            # Create target directory if needed
            $targetDir = if ($item.IsDirectory) { Split-Path $item.Target -Parent } else { Split-Path $item.Target -Parent }
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            
            # Try git mv first, fallback to PowerShell
            if ($script:GitAvailable) {
                & git mv $item.Source $item.Target 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Git moved: $(Split-Path $item.Source -Leaf)"
                    continue
                }
            }
            
            # Fallback to PowerShell move
            if ($item.IsDirectory) {
                if (Test-Path $item.Target) {
                    Remove-Item $item.Target -Recurse -Force
                }
                Move-Item $item.Source $item.Target -Force
            } else {
                Move-Item $item.Source $item.Target -Force
            }
            Write-Success "Moved: $(Split-Path $item.Source -Leaf)"
        }
        catch {
            Write-Warning "Failed to move $($item.Source): $($_.Exception.Message)"
            Write-Info "You may need to move this file manually."
        }
    }
}

function Update-Namespaces {
    Write-Step "Updating namespaces in moved C# files..."
    
    $apiProjectPath = Join-Path $SourceFolder "Accounting.Api"
    $csFiles = Get-ChildItem -Path $apiProjectPath -Filter "*.cs" -Recurse
    $changedFiles = @()
    
    foreach ($file in $csFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            $originalContent = $content
            
            # Replace namespace declarations
            $content = $content -replace "namespace AccountingSystem\b", "namespace Accounting.Api"
            $content = $content -replace "using AccountingSystem\b", "using Accounting.Api"
            
            if ($content -ne $originalContent) {
                Set-Content -Path $file.FullName -Value $content -NoNewline
                $changedFiles += $file.FullName
                Write-Success "Updated namespaces in: $($file.Name)"
            }
        }
        catch {
            Write-Warning "Failed to update namespaces in $($file.Name): $($_.Exception.Message)"
        }
    }
    
    if ($changedFiles.Count -gt 0) {
        Write-Info "Updated namespaces in $($changedFiles.Count) files."
    } else {
        Write-Info "No namespace updates needed."
    }
}

function Add-ProjectReferences {
    Write-Step "Adding project references..."
    
    foreach ($reference in $ProjectReferences) {
        $fromProject = Join-Path $SourceFolder "$($reference.From)\$($reference.From).csproj"
        $toProject = Join-Path $SourceFolder "$($reference.To)\$($reference.To).csproj"
        
        try {
            Write-Info "Adding reference: $($reference.From) -> $($reference.To)"
            & dotnet add $fromProject reference $toProject
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Added reference: $($reference.From) -> $($reference.To)"
            } else {
                Write-Warning "Failed to add reference: $($reference.From) -> $($reference.To)"
            }
        }
        catch {
            Write-Warning "Failed to add reference $($reference.From) -> $($reference.To): $($_.Exception.Message)"
        }
    }
}

function Install-RecommendedPackages {
    if (-not (Confirm-Action "Install recommended NuGet packages to Accounting.Api?")) {
        Write-Info "Skipping NuGet package installation."
        return
    }
    
    $apiProject = Join-Path $SourceFolder "Accounting.Api\Accounting.Api.csproj"
    
    Write-Step "Installing recommended NuGet packages..."
    
    foreach ($package in $RecommendedPackages) {
        try {
            Write-Info "Installing $package..."
            & dotnet add $apiProject package $package
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Installed: $package"
            } else {
                Write-Warning "Failed to install: $package"
            }
        }
        catch {
            Write-Warning "Failed to install $package`: $($_.Exception.Message)"
        }
    }
}

function Test-BuildAndRestore {
    Write-Step "Running restore, build, and test..."
    
    $operations = @(
        @{ Name = "Restore"; Command = "dotnet restore" },
        @{ Name = "Build"; Command = "dotnet build" },
        @{ Name = "Test"; Command = "dotnet test" }
    )
    
    $results = @()
    
    foreach ($operation in $operations) {
        Write-Info "Running $($operation.Name)..."
        try {
            $output = & cmd /c "$($operation.Command) 2>&1"
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($operation.Name) succeeded"
                $results += @{ Operation = $operation.Name; Success = $true; Output = $output }
            } else {
                Write-Warning "$($operation.Name) failed"
                $results += @{ Operation = $operation.Name; Success = $false; Output = $output }
            }
        }
        catch {
            Write-Warning "$($operation.Name) failed with exception: $($_.Exception.Message)"
            $results += @{ Operation = $operation.Name; Success = $false; Output = $_.Exception.Message }
        }
    }
    
    # Print summary
    Write-Info "`n=== Build Summary ==="
    foreach ($result in $results) {
        $status = if ($result.Success) { "✅ PASSED" } else { "❌ FAILED" }
        Write-Host "$($result.Operation): $status" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
    }
    
    $failedOperations = $results | Where-Object { -not $_.Success }
    if ($failedOperations) {
        Write-Warning "`nSome operations failed. Check the output above for details."
        Write-Info "Common fixes:"
        Write-Info "- Fix using statements in moved files"
        Write-Info "- Resolve missing references"
        Write-Info "- Update target framework if needed"
    } else {
        Write-Success "All operations completed successfully!"
    }
}

function Remove-OldProjectFromSolution {
    if (-not (Confirm-Action "Remove the old AccountingSystem project from the solution? (The folder will remain as backup)")) {
        Write-Info "Keeping old project in solution."
        return
    }
    
    Write-Step "Removing old project from solution..."
    
    $oldProject = Join-Path $OriginalProjectFolder "$OriginalProjectFolder.csproj"
    
    try {
        & dotnet sln $SolutionFile remove $oldProject
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Removed old project from solution"
            Write-Info "Note: The original '$OriginalProjectFolder' folder still exists and can be safely deleted after verification."
        } else {
            Write-Warning "Failed to remove old project from solution"
        }
    }
    catch {
        Write-Warning "Failed to remove old project: $($_.Exception.Message)"
    }
}

function Show-NextSteps {
    Write-Info "`n" + "="*80
    Write-Success "MIGRATION COMPLETED!"
    Write-Info "="*80
    
    Write-Info "`n📁 CREATED PROJECTS:"
    foreach ($project in $NewProjects.Keys) {
        Write-Host "   • $project" -ForegroundColor Green
    }
    
    Write-Info "`n📦 BACKUP LOCATION:"
    Write-Host "   • $BackupFolder" -ForegroundColor Yellow
    
    Write-Info "`n🔧 NEXT STEPS:"
    Write-Host "   1. Open the solution in Visual Studio or VS Code" -ForegroundColor Cyan
    Write-Host "   2. Set 'src/Accounting.Api' as the startup project" -ForegroundColor Cyan
    Write-Host "   3. Review and fix any remaining using statements" -ForegroundColor Cyan
    Write-Host "   4. Check launchSettings.json in src/Accounting.Api/Properties/" -ForegroundColor Cyan
    Write-Host "   5. Run the application to verify it works" -ForegroundColor Cyan
    Write-Host "   6. Start implementing Clean Architecture patterns:" -ForegroundColor Cyan
    Write-Host "      • Move domain entities to Accounting.Domain" -ForegroundColor Gray
    Write-Host "      • Move business logic to Accounting.Application" -ForegroundColor Gray
    Write-Host "      • Move data access to Accounting.Infrastructure" -ForegroundColor Gray
    Write-Host "   7. After verification, you can safely delete:" -ForegroundColor Cyan
    Write-Host "      • $OriginalProjectFolder folder (original project)" -ForegroundColor Gray
    Write-Host "      • $BackupFolder folder (backup copy)" -ForegroundColor Gray
    
    Write-Info "`n🧪 VERIFICATION COMMANDS:"
    Write-Host "   dotnet run --project src/Accounting.Api" -ForegroundColor Magenta
    Write-Host "   dotnet test" -ForegroundColor Magenta
    
    Write-Info "`nMigration completed successfully! 🎉"
}

# Main script execution
function Main {
    Write-Host "`n" + "="*80 -ForegroundColor Blue
    Write-Host "   ASP.NET Clean Architecture Migration Script" -ForegroundColor Blue
    Write-Host "="*80 -ForegroundColor Blue
    
    try {
        # Prerequisites check
        if (-not (Test-Prerequisites)) {
            exit 1
        }
        
        # Confirm migration
        Write-Info "`nThis script will:"
        Write-Info "• Create a new git branch (optional)"
        Write-Info "• Backup your current AccountingSystem project"
        Write-Info "• Create new Clean Architecture projects under src/"
        Write-Info "• Move files from AccountingSystem to src/Accounting.Api"
        Write-Info "• Update namespaces and add project references"
        Write-Info "• Install recommended NuGet packages (optional)"
        Write-Info "• Test build and restore"
        
        if (-not (Confirm-Action "`nProceed with migration?")) {
            Write-Info "Migration cancelled by user."
            exit 0
        }
        
        # Execute migration steps
        New-GitBranch
        New-BackupCopy
        New-SourceStructure
        Add-ProjectsToSolution
        Move-ProjectFiles
        Update-Namespaces
        Add-ProjectReferences
        Install-RecommendedPackages
        Test-BuildAndRestore
        Remove-OldProjectFromSolution
        Show-NextSteps
        
    }
    catch {
        Write-Error "Migration failed: $($_.Exception.Message)"
        Write-Info "Check the backup at '$BackupFolder' to restore if needed."
        exit 1
    }
}

# Run the script
Main

# Run from repository root (where AccountingSystem.sln exists)
.\migrate-to-src.ps1

# Or specify branch name directly
.\migrate-to-src.ps1 -BranchName "feature/clean-architecture"