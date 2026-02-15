# Zaika Django Deployment Script
# This script automates the deployment process on Windows VPS
# Run with: .\deploy.ps1

param(
    [switch]$Production,
    [switch]$SkipMigrations,
    [switch]$SkipStatic
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Zaika Django Deployment Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some operations may fail." -ForegroundColor Yellow
}

# Project directory
$projectDir = "C:\inetpub\zaika"
Set-Location $projectDir

Write-Host "[1/7] Checking environment..." -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file from .env.example" -ForegroundColor Yellow
    exit 1
}

Write-Host "[2/7] Activating virtual environment..." -ForegroundColor Green
.\venv\Scripts\Activate.ps1

Write-Host "[3/7] Installing/Updating dependencies..." -ForegroundColor Green
python -m pip install --upgrade pip
pip install -r requirements.txt

if (-not $SkipMigrations) {
    Write-Host "[4/7] Running database migrations..." -ForegroundColor Green
    python manage.py migrate --noinput
} else {
    Write-Host "[4/7] Skipping migrations..." -ForegroundColor Yellow
}

if (-not $SkipStatic) {
    Write-Host "[5/7] Collecting static files..." -ForegroundColor Green
    python manage.py collectstatic --noinput --clear
} else {
    Write-Host "[5/7] Skipping static files..." -ForegroundColor Yellow
}

Write-Host "[6/7] Running Django checks..." -ForegroundColor Green
if ($Production) {
    python manage.py check --deploy
} else {
    python manage.py check
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Django check failed!" -ForegroundColor Red
    exit 1
}

Write-Host "[7/7] Restarting application service..." -ForegroundColor Green
try {
    Restart-Service ZaikaaDjangoApp -ErrorAction Stop
    Write-Host "Service restarted successfully!" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Could not restart service. You may need to restart manually." -ForegroundColor Yellow
    Write-Host "Run: Restart-Service ZaikaaDjangoApp" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Deployment completed successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Test the application at your domain/IP" -ForegroundColor White
Write-Host "  2. Check service status: Get-Service ZaikaaDjangoApp" -ForegroundColor White
Write-Host "  3. Monitor logs for any errors" -ForegroundColor White
