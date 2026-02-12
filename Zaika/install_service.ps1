# Windows Service Installation Script for Zaika Django App
# This script creates a Windows service that runs the Django application
# Requires NSSM (Non-Sucking Service Manager)

# Configuration
$serviceName = "ZaikaaDjangoApp"
$serviceDisplayName = "Zaikaa Restaurant Ordering System"
$serviceDescription = "Django web application for Zaikaa restaurant ordering and payment system"
$projectPath = "C:\inetpub\zaika"
$pythonPath = "$projectPath\venv\Scripts\python.exe"
$scriptPath = "$projectPath\run_waitress.py"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Zaika Django Service Installation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check if Chocolatey is installed
Write-Host "[1/5] Checking for Chocolatey..." -ForegroundColor Green
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "Chocolatey is already installed." -ForegroundColor White
}

# Install NSSM
Write-Host "[2/5] Installing NSSM (Non-Sucking Service Manager)..." -ForegroundColor Green
choco install nssm -y

# Check if service already exists
Write-Host "[3/5] Checking for existing service..." -ForegroundColor Green
$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "Service already exists. Stopping and removing..." -ForegroundColor Yellow
    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
    nssm remove $serviceName confirm
    Start-Sleep -Seconds 2
}

# Install service
Write-Host "[4/5] Installing service..." -ForegroundColor Green
nssm install $serviceName $pythonPath $scriptPath

# Configure service
Write-Host "[5/5] Configuring service..." -ForegroundColor Green
nssm set $serviceName AppDirectory $projectPath
nssm set $serviceName DisplayName $serviceDisplayName
nssm set $serviceName Description $serviceDescription
nssm set $serviceName Start SERVICE_AUTO_START
nssm set $serviceName AppStdout "$projectPath\logs\service_output.log"
nssm set $serviceName AppStderr "$projectPath\logs\service_error.log"

# Create logs directory
$logsDir = "$projectPath\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

Write-Host ""
Write-Host "Service installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Service Details:" -ForegroundColor Cyan
Write-Host "  Name: $serviceName" -ForegroundColor White
Write-Host "  Display Name: $serviceDisplayName" -ForegroundColor White
Write-Host "  Python Path: $pythonPath" -ForegroundColor White
Write-Host "  Script Path: $scriptPath" -ForegroundColor White
Write-Host "  Logs: $logsDir" -ForegroundColor White
Write-Host ""

# Ask if user wants to start the service
$startService = Read-Host "Do you want to start the service now? (Y/N)"
if ($startService -eq "Y" -or $startService -eq "y") {
    Write-Host "Starting service..." -ForegroundColor Green
    nssm start $serviceName
    Start-Sleep -Seconds 3
    
    $service = Get-Service -Name $serviceName
    if ($service.Status -eq "Running") {
        Write-Host "Service started successfully!" -ForegroundColor Green
        Write-Host "The application should now be accessible at http://localhost:8000" -ForegroundColor White
    } else {
        Write-Host "WARNING: Service failed to start!" -ForegroundColor Red
        Write-Host "Check the logs at: $logsDir" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  Start Service:   Start-Service $serviceName" -ForegroundColor White
Write-Host "  Stop Service:    Stop-Service $serviceName" -ForegroundColor White
Write-Host "  Restart Service: Restart-Service $serviceName" -ForegroundColor White
Write-Host "  Check Status:    Get-Service $serviceName" -ForegroundColor White
Write-Host "  View Logs:       Get-Content $logsDir\service_output.log -Tail 50" -ForegroundColor White
Write-Host ""
