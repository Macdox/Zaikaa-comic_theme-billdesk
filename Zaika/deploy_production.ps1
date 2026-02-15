# ===========================================
# ZAIKA BILLDESK PRODUCTION DEPLOYMENT SCRIPT
# ===========================================
# Run as Administrator: .\deploy_production.ps1

param(
    [switch]$Setup,
    [switch]$CollectStatic,
    [switch]$RunServer,
    [switch]$AddToPM2
)

$ErrorActionPreference = "Stop"
$ProjectPath = "C:\Users\Administrator\Desktop\Pratishtha\Zaikaa-comic_theme-billdesk\Zaika"
$PythonPath = "C:\Users\Administrator\AppData\Local\Programs\Python\Python313\python.exe"
$AppName = "ZaikaBillDesk"

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
}

function Install-Requirements {
    Write-Header "Installing Python Dependencies"
    Set-Location $ProjectPath
    & $PythonPath -m pip install --upgrade pip
    & $PythonPath -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw "Failed to install requirements" }
    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
}

function Collect-StaticFiles {
    Write-Header "Collecting Static Files"
    Set-Location $ProjectPath
    & $PythonPath manage.py collectstatic --noinput
    if ($LASTEXITCODE -ne 0) { throw "Failed to collect static files" }
    Write-Host "Static files collected successfully!" -ForegroundColor Green
}

function Run-Migrations {
    Write-Header "Running Database Migrations"
    Set-Location $ProjectPath
    & $PythonPath manage.py migrate --noinput
    if ($LASTEXITCODE -ne 0) { throw "Failed to run migrations" }
    Write-Host "Migrations completed successfully!" -ForegroundColor Green
}

function Start-DevServer {
    Write-Header "Starting Production Server"
    Set-Location $ProjectPath
    & $PythonPath run_waitress.py
}

function Add-ToPM2 {
    Write-Header "Adding to PM2"
    Set-Location $ProjectPath
    
    # Check if already exists in PM2
    $pm2List = pm2 jlist 2>$null | ConvertFrom-Json
    $exists = $pm2List | Where-Object { $_.name -eq $AppName }
    
    if ($exists) {
        Write-Host "Stopping existing PM2 process..." -ForegroundColor Yellow
        pm2 delete $AppName
    }
    
    # Start with PM2
    pm2 start $PythonPath --name $AppName --interpreter none -- run_waitress.py
    pm2 save
    
    Write-Host "Added to PM2 as '$AppName'" -ForegroundColor Green
    Write-Host "Use 'pm2 logs $AppName' to view logs" -ForegroundColor Cyan
}

function Open-FirewallPort {
    Write-Header "Configuring Firewall"
    
    # Remove existing rule if exists
    Remove-NetFirewallRule -DisplayName "Zaika BillDesk Server" -ErrorAction SilentlyContinue
    
    # Add firewall rule for port 8002
    New-NetFirewallRule -DisplayName "Zaika BillDesk Server" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 8002 `
        -Action Allow `
        -Profile Any
    
    Write-Host "Firewall rule added for port 8002" -ForegroundColor Green
}

function Full-Setup {
    Write-Header "FULL PRODUCTION SETUP"
    
    Install-Requirements
    Run-Migrations
    Collect-StaticFiles
    Open-FirewallPort
    
    Write-Host ""
    Write-Host "=" * 50 -ForegroundColor Green
    Write-Host "SETUP COMPLETE!" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: .\deploy_production.ps1 -AddToPM2" -ForegroundColor White
    Write-Host "   OR" -ForegroundColor White
    Write-Host "2. Run: .\deploy_production.ps1 -RunServer" -ForegroundColor White
    Write-Host ""
    Write-Host "Server will be available at: http://localhost:8002/zaikaa" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
try {
    Set-Location $ProjectPath
    
    if ($Setup) {
        Full-Setup
    }
    elseif ($CollectStatic) {
        Collect-StaticFiles
    }
    elseif ($AddToPM2) {
        Add-ToPM2
    }
    elseif ($RunServer) {
        Start-DevServer
    }
    else {
        Write-Host ""
        Write-Host "ZAIKA BILLDESK DEPLOYMENT SCRIPT" -ForegroundColor Cyan
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host "  .\deploy_production.ps1 -Setup          # Full setup (install deps, migrate, collect static)"
        Write-Host "  .\deploy_production.ps1 -CollectStatic  # Collect static files only"
        Write-Host "  .\deploy_production.ps1 -AddToPM2       # Add to PM2 process manager"
        Write-Host "  .\deploy_production.ps1 -RunServer      # Run server in foreground (for testing)"
        Write-Host ""
    }
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
