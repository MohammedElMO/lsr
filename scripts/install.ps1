#!/usr/bin/env pwsh

param(
    [string]$InstallDir = "$env:USERPROFILE\.local\bin",
    [switch]$Help
)

# Configuration
$REPO = "MohammedElMO/lsrs"  # Replace with your actual repo
$BINARY_NAME = "lsrs"

# Show help
if ($Help) {
    Write-Host "Usage: .\install.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -InstallDir <path>  Installation directory (default: %USERPROFILE%\.local\bin)"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1"
    Write-Host "  .\install.ps1 -InstallDir C:\tools"
    exit 0
}

# Helper functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

# Get latest release version
function Get-LatestVersion {
    Write-Info "Fetching latest release..."
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest"
        return $response.tag_name -replace '^v', ''
    }
    catch {
        Write-Error "Failed to fetch latest release: $($_.Exception.Message)"
        exit 1
    }
}

# Download and install
function Install-Binary {
    param(
        [string]$Version
    )

    $platform = "x86_64-pc-windows-msvc"
    $archiveName = "$BINARY_NAME-$platform.zip"
    $downloadUrl = "https://github.com/$REPO/releases/download/v$Version/$archiveName"

    Write-Info "Downloading $BINARY_NAME v$Version for $platform..."

    # Create temp directory
    $tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        # Download archive
        $archivePath = Join-Path $tempDir $archiveName
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -ErrorAction Stop

        # Extract archive
        Expand-Archive -Path $archivePath -DestinationPath $tempDir -Force

        # Find binary
        $binaryPath = Join-Path $tempDir "$BINARY_NAME.exe"
        if (-not (Test-Path $binaryPath)) {
            Write-Error "Binary $BINARY_NAME.exe not found in archive"
            exit 1
        }

        # Create install directory if it doesn't exist
        if (-not (Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        }

        # Install binary
        $installPath = Join-Path $InstallDir "$BINARY_NAME.exe"
        Write-Info "Installing to $installPath..."
        Copy-Item $binaryPath $installPath -Force

        Write-Info "✅ $BINARY_NAME installed successfully!"

    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Error "Please check if the release exists: https://github.com/$REPO/releases"
        exit 1
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }
}

# Verify installation
function Test-Installation {
    $binaryPath = Join-Path $InstallDir "$BINARY_NAME.exe"

    if (Test-Path $binaryPath) {
        try {
            $version = & $binaryPath --version 2>$null | Select-Object -First 1
            Write-Info "🎉 Installation verified: $version"
            Write-Info "Run '$BINARY_NAME --help' to get started"
        }
        catch {
            Write-Info "Binary installed at $binaryPath"
        }

        # Check if in PATH
        $pathDirs = $env:PATH -split ';'
        if ($InstallDir -notin $pathDirs) {
            Write-Warn "Install directory is not in PATH"
            Write-Warn "Add to PATH manually or run:"
            Write-Warn "`$env:PATH += `";$InstallDir`""
        }
    }
    else {
        Write-Error "Installation verification failed"
        exit 1
    }
}

# Main execution
Write-Info "Installing $BINARY_NAME..."

$version = Get-LatestVersion
Write-Info "Latest version: v$version"
Write-Info "Install directory: $InstallDir"

Install-Binary -Version $version
Test-Installation