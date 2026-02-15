# Zaika Django Project - Windows VPS Deployment Guide

This guide provides step-by-step instructions for deploying the Zaika restaurant ordering system on a Windows VPS.

## Prerequisites

- Windows VPS with Administrator access
- Domain name (optional but recommended for SSL)
- Remote Desktop Connection to VPS
- Basic knowledge of PowerShell and Windows Server

## Table of Contents

1. [Initial VPS Setup](#1-initial-vps-setup)
2. [Install Required Software](#2-install-required-software)
3. [Project Deployment](#3-project-deployment)
4. [Web Server Configuration](#4-web-server-configuration)
5. [SSL Certificate Setup](#5-ssl-certificate-setup)
6. [Production Configuration](#6-production-configuration)
7. [Maintenance & Monitoring](#7-maintenance--monitoring)

---

## 1. Initial VPS Setup

### 1.1 Connect to VPS
```powershell
# Use Remote Desktop Connection (mstsc.exe)
# Enter your VPS IP address and credentials
```

### 1.2 Update Windows
```powershell
# Run Windows Update
Start-Process ms-settings:windowsupdate
```

### 1.3 Configure Firewall
```powershell
# Allow HTTP (port 80)
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

# Allow HTTPS (port 443)
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow

# Allow PostgreSQL (if database is on same server)
New-NetFirewallRule -DisplayName "Allow PostgreSQL" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow
```

---

## 2. Install Required Software

### 2.1 Install Python 3.12
```powershell
# Download Python installer
$pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
$pythonInstaller = "$env:TEMP\python-installer.exe"
Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller

# Install Python (add to PATH)
Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

# Verify installation
python --version
pip --version
```

### 2.2 Install PostgreSQL
```powershell
# Download PostgreSQL installer
$postgresUrl = "https://get.enterprisedb.com/postgresql/postgresql-16.1-1-windows-x64.exe"
$postgresInstaller = "$env:TEMP\postgresql-installer.exe"
Invoke-WebRequest -Uri $postgresUrl -OutFile $postgresInstaller

# Run installer (interactive - follow prompts)
Start-Process -FilePath $postgresInstaller -Wait
```

**PostgreSQL Setup:**
- Set a strong password for the `postgres` user
- Default port: 5432
- Install pgAdmin (recommended)

### 2.3 Install Git (Optional)
```powershell
# Download Git installer
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
$gitInstaller = "$env:TEMP\git-installer.exe"
Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller

# Install Git
Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT" -Wait
```

---

## 3. Project Deployment

### 3.1 Transfer Project Files

**Option A: Using Git**
```powershell
# Create project directory
New-Item -ItemType Directory -Path "C:\inetpub\zaika" -Force
cd C:\inetpub\zaika

# Clone repository (if using Git)
git clone <your-repository-url> .
```

**Option B: Manual Transfer**
- Use FileZilla, WinSCP, or Remote Desktop to copy files
- Copy the entire project to `C:\inetpub\zaika`

### 3.2 Set Up Virtual Environment
```powershell
# Navigate to project directory
cd C:\inetpub\zaika

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Upgrade pip
python -m pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
```

### 3.3 Configure Environment Variables

Create `.env` file in the project root:
```powershell
# Copy example file
Copy-Item .env.example .env

# Edit .env file with production values
notepad .env
```

**Production `.env` Configuration:**
```env
# Django Settings
SECRET_KEY=<generate-new-secret-key>
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,<your-vps-ip>

# Database Configuration
DB_ENGINE=django.db.backends.postgresql
DB_NAME=zaikaa_production
DB_USER=zaikaa_user
DB_PASSWORD=<strong-database-password>
DB_HOST=localhost
DB_PORT=5432

# Razorpay Production Keys
RAZORPAY_KEY_ID=rzp_live_uJ1VIqrWCu5P0o
RAZORPAY_SECRET_KEY=Sd8tttdUJXKrhOWmZdXqMHNm

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
EMAIL_USE_TLS=True

# Static Files
STATIC_ROOT=C:/inetpub/zaika/staticfiles

# MongoDB (if using)
MONGO_URI=mongodb://localhost:27017/
MONGO_DB_NAME=zaikaa_db
```

> [!IMPORTANT]
> **Generate a New SECRET_KEY:**
> ```powershell
> python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
> ```

### 3.4 Set Up Database
```powershell
# Open PostgreSQL command line
psql -U postgres

# Create database and user
CREATE DATABASE zaikaa_production;
CREATE USER zaikaa_user WITH PASSWORD 'your-strong-password';
ALTER ROLE zaikaa_user SET client_encoding TO 'utf8';
ALTER ROLE zaikaa_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE zaikaa_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE zaikaa_production TO zaikaa_user;
\q
```

### 3.5 Run Migrations
```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput
```

---

## 4. Web Server Configuration

### Option A: Waitress (Recommended - Easier Setup)

#### 4.1 Create Waitress Server Script

Create `run_waitress.py` in project root:
```python
from waitress import serve
from Zaikaa.wsgi import application
import os

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    serve(application, host='0.0.0.0', port=port, threads=4)
```

#### 4.2 Create Windows Service

Create `install_service.ps1`:
```powershell
# This script creates a Windows service for the Django app
$serviceName = "ZaikaaDjangoApp"
$serviceDisplayName = "Zaikaa Restaurant Ordering System"
$serviceDescription = "Django application for Zaikaa restaurant ordering"
$pythonPath = "C:\inetpub\zaika\venv\Scripts\python.exe"
$scriptPath = "C:\inetpub\zaika\run_waitress.py"

# Install NSSM (Non-Sucking Service Manager)
choco install nssm -y

# Create service
nssm install $serviceName $pythonPath $scriptPath
nssm set $serviceName AppDirectory "C:\inetpub\zaika"
nssm set $serviceName DisplayName $serviceDisplayName
nssm set $serviceName Description $serviceDescription
nssm set $serviceName Start SERVICE_AUTO_START

# Start service
nssm start $serviceName

Write-Host "Service installed and started successfully!"
```

#### 4.3 Install and Run Service
```powershell
# Run as Administrator
.\install_service.ps1

# Check service status
Get-Service ZaikaaDjangoApp

# Start/Stop service
Start-Service ZaikaaDjangoApp
Stop-Service ZaikaaDjangoApp
```

### Option B: IIS with wfastcgi (Windows Native)

#### 4.1 Install IIS
```powershell
# Enable IIS
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CGI

# Install IIS Management Console
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
```

#### 4.2 Install wfastcgi
```powershell
.\venv\Scripts\Activate.ps1
pip install wfastcgi
wfastcgi-enable
```

#### 4.3 Create web.config

Create `web.config` in project root - see the separate `web.config` file created.

---

## 5. SSL Certificate Setup

### Option A: Let's Encrypt (Free, Automated)

```powershell
# Install Certbot for Windows
choco install certbot -y

# Get certificate
certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Certificate location: C:\Certbot\live\yourdomain.com\
```

### Option B: Commercial SSL Certificate

1. Purchase SSL certificate from a provider
2. Generate CSR and private key
3. Install certificate in IIS or configure with reverse proxy

---

## 6. Production Configuration

### 6.1 Security Checklist

- ✅ `DEBUG = False` in production
- ✅ Change `SECRET_KEY` to a new random value
- ✅ Set proper `ALLOWED_HOSTS`
- ✅ Use HTTPS only
- ✅ Secure database credentials
- ✅ Enable CSRF protection
- ✅ Use production Razorpay keys

### 6.2 Performance Optimization

```python
# Add to settings.py for production
CONN_MAX_AGE = 600  # Database connection pooling
SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'
```

---

## 7. Maintenance & Monitoring

### 7.1 Database Backup Script

Create `backup_database.ps1`:
```powershell
$backupDir = "C:\Backups\Zaikaa"
$date = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFile = "$backupDir\zaikaa_backup_$date.sql"

# Create backup directory if not exists
New-Item -ItemType Directory -Path $backupDir -Force

# Backup database
$env:PGPASSWORD = "your-database-password"
pg_dump -U zaikaa_user -h localhost -d zaikaa_production -F c -f $backupFile

Write-Host "Backup completed: $backupFile"
```

### 7.2 Schedule Automated Backups
```powershell
# Create scheduled task for daily backups
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\inetpub\zaika\backup_database.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "ZaikaaBackup" -Action $action -Trigger $trigger -RunLevel Highest
```

### 7.3 Monitor Logs
```powershell
# Django logs location (configure in settings.py)
# C:\inetpub\zaika\logs\django.log

# Windows Event Viewer
eventvwr.msc
```

---

## Troubleshooting

### Common Issues

**1. Static files not loading**
```powershell
python manage.py collectstatic --clear --noinput
```

**2. Database connection errors**
- Check PostgreSQL service is running
- Verify `.env` database credentials
- Check firewall rules

**3. Permission errors**
```powershell
# Grant IIS user permissions
icacls C:\inetpub\zaika /grant "IUSR:(OI)(CI)F" /T
```

**4. Service won't start**
- Check Windows Event Viewer
- Verify virtual environment path
- Check `.env` file exists

---

## Quick Commands Reference

```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser

# Check Django configuration
python manage.py check --deploy

# Run development server (testing only)
python manage.py runserver 0.0.0.0:8000

# Restart Waitress service
Restart-Service ZaikaaDjangoApp

# View service logs
Get-EventLog -LogName Application -Source ZaikaaDjangoApp -Newest 50
```

---

## Post-Deployment Checklist

- [ ] Django admin accessible at `/admin`
- [ ] Static files loading correctly
- [ ] User registration works
- [ ] Order placement works
- [ ] Payment gateway (Razorpay) functional
- [ ] Email notifications working
- [ ] SSL certificate valid
- [ ] Database backups scheduled
- [ ] Monitoring configured
- [ ] Domain DNS configured

---

## Support

For issues or questions:
1. Check Django logs: `C:\inetpub\zaika\logs\`
2. Check Windows Event Viewer
3. Review [Django deployment checklist](https://docs.djangoproject.com/en/5.0/howto/deployment/checklist/)
