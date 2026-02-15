# Quick Start Guide for Local Development

## Prerequisites
- Python 3.12 installed
- PostgreSQL installed and running
- Git (optional)

## Setup Instructions

### 1. Clone or Download Project
```bash
# If using Git
git clone <repository-url>
cd Zaika

# Or download and extract ZIP file
```

### 2. Create Virtual Environment
```powershell
# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Upgrade pip
python -m pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure Environment Variables
```powershell
# Copy example environment file
Copy-Item .env.example .env

# Edit .env file with your settings
notepad .env
```

**Update these values in `.env`:**
- `SECRET_KEY` - Generate new key (see below)
- `DB_PASSWORD` - Your PostgreSQL password
- `EMAIL_HOST_USER` - Your email
- `EMAIL_HOST_PASSWORD` - Your email app password
- `RAZORPAY_KEY_ID` - Your Razorpay test key
- `RAZORPAY_SECRET_KEY` - Your Razorpay test secret

**Generate new SECRET_KEY:**
```powershell
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 4. Set Up Database
```powershell
# Open PostgreSQL command line
psql -U postgres

# Create database
CREATE DATABASE zaikaa;
\q
```

### 5. Run Migrations
```powershell
# Make sure virtual environment is activated
.\venv\Scripts\Activate.ps1

# Run migrations
python manage.py migrate

# Create superuser (admin account)
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput
```

### 6. Run Development Server
```powershell
# Start development server
python manage.py runserver

# Access the application at: http://localhost:8000
# Admin panel at: http://localhost:8000/admin
```

## Common Development Commands

```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Run development server
python manage.py runserver

# Run migrations
python manage.py migrate

# Create migrations
python manage.py makemigrations

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic

# Open Django shell
python manage.py shell

# Check for issues
python manage.py check
```

## Project Structure

```
Zaika/
├── venv/                   # Virtual environment (auto-generated)
├── Zaikaa/                 # Main project settings
│   ├── settings.py         # Django settings (uses .env)
│   ├── urls.py            # Main URL configuration
│   └── wsgi.py            # WSGI application
├── food/                   # Main application
│   ├── templates/         # HTML templates
│   ├── static/           # Static files (CSS, JS, images)
│   ├── views.py          # View functions
│   ├── urls.py           # App URL routes
│   └── models.py         # Database models
├── staticfiles/           # Collected static files
├── .env                   # Environment variables (DO NOT COMMIT)
├── .env.example          # Environment template
├── requirements.txt      # Python dependencies
└── manage.py             # Django management script
```

## Features

- User authentication (registration, login, logout)
- Restaurant menu browsing
- Order placement and management
- Razorpay payment integration
- Admin panel for order management
- Stall vendor interface
- Email notifications
- Order history and tracking

## Troubleshooting

**Issue: ModuleNotFoundError**
```powershell
# Make sure virtual environment is activated
.\venv\Scripts\Activate.ps1

# Reinstall dependencies
pip install -r requirements.txt
```

**Issue: Database connection error**
- Check PostgreSQL is running
- Verify `.env` database credentials
- Ensure database exists

**Issue: Static files not loading**
```powershell
python manage.py collectstatic --noinput
```

**Issue: Migration errors**
```powershell
# Delete migrations and recreate
python manage.py migrate --fake-initial
```

## For Production Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete Windows VPS deployment instructions.

## Support

- Check Django documentation: https://docs.djangoproject.com/
- PostgreSQL docs: https://www.postgresql.org/docs/
- Razorpay API docs: https://razorpay.com/docs/
