# Database Schema Fix Script
# This script fixes the missing columns in the users table
# Run with: .\fix_database.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlFile = Join-Path $scriptDir "fix_users_table.sql"

# Database configuration from .env file
$envFile = Join-Path $scriptDir ".env"
$dbName = "zaikaa"
$dbUser = "postgres"
$dbPassword = "#Raj0977"
$dbHost = "localhost"
$dbPort = "5432"

# Read from .env if exists
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^DB_NAME=(.+)$") { $dbName = $matches[1] }
        if ($_ -match "^DB_USER=(.+)$") { $dbUser = $matches[1] }
        if ($_ -match "^DB_PASSWORD=(.+)$") { $dbPassword = $matches[1] }
        if ($_ -match "^DB_HOST=(.+)$") { $dbHost = $matches[1] }
        if ($_ -match "^DB_PORT=(.+)$") { $dbPort = $matches[1] }
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Zaika Database Schema Fix" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database: $dbName" -ForegroundColor White
Write-Host "User: $dbUser" -ForegroundColor White
Write-Host "Host: ${dbHost}:${dbPort}" -ForegroundColor White
Write-Host ""

# Set PostgreSQL password environment variable
$env:PGPASSWORD = $dbPassword

# Find psql executable
$psqlPath = "C:\Program Files\PostgreSQL\16\bin\psql.exe"
if (-not (Test-Path $psqlPath)) {
    $psqlPath = "C:\Program Files\PostgreSQL\15\bin\psql.exe"
}
if (-not (Test-Path $psqlPath)) {
    $psqlPath = "psql"  # Try PATH
}

Write-Host "Running database fix script..." -ForegroundColor Green
try {
    & $psqlPath -U $dbUser -h $dbHost -p $dbPort -d $dbName -f $sqlFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Database schema updated successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "The users table now has the required columns:" -ForegroundColor White
        Write-Host "  - year (for students)" -ForegroundColor White
        Write-Host "  - branch (for students)" -ForegroundColor White
        Write-Host "  - role (student/staff)" -ForegroundColor White
        Write-Host ""
        Write-Host "You can now restart your Django application and try signing up again." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "ERROR: Database fix failed!" -ForegroundColor Red
        Write-Host "Please check the error messages above." -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to connect to database!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. PostgreSQL is running" -ForegroundColor Yellow
    Write-Host "  2. Database credentials in .env are correct" -ForegroundColor Yellow
    Write-Host "  3. psql is installed and accessible" -ForegroundColor Yellow
}

# Clear password from environment
Remove-Item Env:\PGPASSWORD
