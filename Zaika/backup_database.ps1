# Database Backup Script for Zaika PostgreSQL Database
# Schedule this script to run daily using Windows Task Scheduler
# Usage: .\backup_database.ps1

# Configuration
$backupDir = "C:\Backups\Zaikaa"
$dbName = "zaikaa"
$dbUser = "postgres"
$dbHost = "localhost"
$dbPort = "5432"
$retentionDays = 30  # Keep backups for 30 days

# Get credentials from .env or set manually
$envFile = "C:\inetpub\zaika\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^DB_PASSWORD=(.+)$") {
            $env:PGPASSWORD = $matches[1]
        }
        if ($_ -match "^DB_NAME=(.+)$") {
            $dbName = $matches[1]
        }
        if ($_ -match "^DB_USER=(.+)$") {
            $dbUser = $matches[1]
        }
    }
}

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Green
}

# Generate backup filename with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFile = Join-Path $backupDir "zaikaa_backup_$timestamp.sql"

Write-Host "Starting database backup..." -ForegroundColor Cyan
Write-Host "Database: $dbName" -ForegroundColor White
Write-Host "Backup file: $backupFile" -ForegroundColor White

# Perform backup
try {
    $pgDumpPath = "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe"
    
    if (-not (Test-Path $pgDumpPath)) {
        # Try to find pg_dump in PATH
        $pgDumpPath = "pg_dump"
    }
    
    & $pgDumpPath -U $dbUser -h $dbHost -p $dbPort -d $dbName -F c -f $backupFile
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $backupFile).Length / 1MB
        Write-Host "Backup completed successfully!" -ForegroundColor Green
        Write-Host "File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor White
    } else {
        Write-Host "Backup failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Backup failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Clean up old backups
Write-Host "`nCleaning up old backups (older than $retentionDays days)..." -ForegroundColor Cyan
$oldBackups = Get-ChildItem -Path $backupDir -Filter "zaikaa_backup_*.sql" | 
              Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retentionDays) }

if ($oldBackups) {
    foreach ($oldBackup in $oldBackups) {
        Remove-Item $oldBackup.FullName -Force
        Write-Host "Deleted old backup: $($oldBackup.Name)" -ForegroundColor Yellow
    }
} else {
    Write-Host "No old backups to delete." -ForegroundColor White
}

# List current backups
Write-Host "`nCurrent backups:" -ForegroundColor Cyan
$backups = Get-ChildItem -Path $backupDir -Filter "zaikaa_backup_*.sql" | Sort-Object LastWriteTime -Descending
foreach ($backup in $backups) {
    $size = [math]::Round($backup.Length / 1MB, 2)
    Write-Host "  $($backup.Name) - $size MB - $($backup.LastWriteTime)" -ForegroundColor White
}

Write-Host "`nBackup process completed!" -ForegroundColor Green
