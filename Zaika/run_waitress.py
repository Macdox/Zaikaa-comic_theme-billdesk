"""
Waitress Production Server for Zaika Django Application
Run this script to start the production WSGI server
"""
from waitress import serve
from Zaikaa.wsgi import application
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

if __name__ == '__main__':
    # Get port from environment or use default
    port = int(os.getenv('PORT', '8000'))
    host = os.getenv('HOST', '0.0.0.0')
    threads = int(os.getenv('WAITRESS_THREADS', '4'))
    
    print(f"Starting Waitress server on {host}:{port}")
    print(f"Threads: {threads}")
    print(f"Django DEBUG mode: {os.getenv('DEBUG', 'False')}")
    print("Press Ctrl+C to stop the server")
    
    # Serve the application
    serve(
        application,
        host=host,
        port=port,
        threads=threads,
        url_scheme='http',  # Change to 'https' if using SSL termination
        channel_timeout=120
    )
