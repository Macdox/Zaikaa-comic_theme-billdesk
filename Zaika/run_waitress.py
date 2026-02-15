"""
Waitress Production Server for Zaika BillDesk Django Application
Run this script to start the production WSGI server
"""
from waitress import serve
from Zaikaa.wsgi import application
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def main():
    # Get configuration from environment
    port = int(os.getenv('PORT', '8002'))
    host = os.getenv('HOST', '0.0.0.0')
    threads = int(os.getenv('WAITRESS_THREADS', '8'))
    debug = os.getenv('DEBUG', 'False') == 'True'
    
    print("=" * 50)
    print("ZAIKA BILLDESK PRODUCTION SERVER")
    print("=" * 50)
    print(f"Host: {host}")
    print(f"Port: {port}")
    print(f"Threads: {threads}")
    print(f"Debug Mode: {debug}")
    print(f"URL: http://{host}:{port}")
    print("=" * 50)
    print("Press Ctrl+C to stop the server")
    print("")
    
    try:
        # Serve the application
        serve(
            application,
            host=host,
            port=port,
            threads=threads,
            url_scheme='https',  # For reverse proxy with SSL
            channel_timeout=120,
            connection_limit=1000,
            cleanup_interval=30,
            recv_bytes=8192,
            send_bytes=8192,
            expose_tracebacks=debug,
            ident='ZaikaBillDesk',
        )
    except KeyboardInterrupt:
        print("\nServer stopped.")
        sys.exit(0)
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
