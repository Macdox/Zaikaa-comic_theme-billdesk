import os
import json
import time
import random
import string
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
import requests

from .encryptPayload import encrypt_payload
from .signedpayload import sign_payload
from .decryptPaylaod import decrypt_payload, verify_jws_payload


load_dotenv()


class BillDeskUtil:
    """
    BillDesk Payment Gateway Utility
    Handles signature generation and verification for BillDesk API v1.2
    """
    
    def __init__(self):
        self.merchant_id = os.getenv("BILLDESK_MERCHANT_ID")
        self.client_id = os.getenv("BILLDESK_CLIENT_ID")
        self.encryption_key = os.getenv("BILLDESK_ENCRYPTION_KEY")
        self.signing_key = os.getenv("BILLDESK_SIGNING_KEY")
        self.base_url = os.getenv("BILLDESK_BASE_URL", "https://pguat.billdesk.io")  # UAT URL, change for production
    
    def validate_config(self):
        """Validate BillDesk configuration"""
        if not all([self.merchant_id, self.client_id, self.encryption_key, self.signing_key]):
            raise ValueError(
                "BillDesk configuration missing. Please set BILLDESK_MERCHANT_ID, "
                "BILLDESK_CLIENT_ID, BILLDESK_ENCRYPTION_KEY, and BILLDESK_SIGNING_KEY "
                "in environment variables."
            )
        return True
    
    def generate_trace_id(self):
        """Generate a unique trace ID for request tracking"""
        timestamp = int(time.time() * 1000)
        random_suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        return f"TRC{timestamp}{random_suffix}"
    
    def get_ist_timestamp(self):
        """Get current timestamp in IST format (YYYYMMDDHHmmss)"""
        # IST is UTC+5:30
        ist_offset = timedelta(hours=5, minutes=30)
        ist_tz = timezone(ist_offset)
        now = datetime.now(ist_tz)
        return now.strftime("%Y%m%d%H%M%S")
    
    def get_endpoints(self):
        """Get BillDesk API endpoints"""
        return {
            "create_order": f"{self.base_url}/payments/ve1_2/orders/create",
            "order_status": f"{self.base_url}/pgsi/v1/pgi/orders/status",
            "refund": f"{self.base_url}/pgsi/v1/pgi/refunds"
        }
    
    def create_order(self, order_payload):
        """
        Make API call to BillDesk to create order
        
        Args:
            order_payload: Order payload (dict)
        
        Returns:
            dict: BillDesk response with redirect URL
        """
        # Encrypt the payload
        encrypted_payload = encrypt_payload(order_payload)
        
        # Sign the encrypted payload
        signed_payload = sign_payload(encrypted_payload)
        
        trace_id = self.generate_trace_id()
        timestamp = self.get_ist_timestamp()
        
        headers = {
            "Content-Type": "application/jose",
            "Accept": "application/jose",
            "BD-Traceid": trace_id,
            "BD-Timestamp": timestamp
        }
        
        response = requests.post(
            self.get_endpoints()["create_order"],
            headers=headers,
            data=signed_payload
        )
        
        response_text = response.text
        
        if not response.ok:
            try:
                # BillDesk sends error as JWS (signed)
                jws = response_text
                
                # Verify JWS -> get JWE
                jwe = verify_jws_payload(jws)
                
                # Decrypt JWE -> get actual JSON error
                decrypted_payload = decrypt_payload(jwe)
                
                print(f"Decrypted BillDesk error: {decrypted_payload}")
                
                # Parse error JSON
                try:
                    error_json = json.loads(decrypted_payload)
                except json.JSONDecodeError:
                    error_json = {"message": decrypted_payload}
                
                error_code = error_json.get("error_code", "UNKNOWN")
                error_message = error_json.get("message", response.reason)
                raise Exception(f"BillDesk Error [{error_code}]: {error_message}")
                
            except Exception as e:
                print(f"Failed to decrypt BillDesk error: {e}")
                # Fallback if decryption fails
                raise Exception(f"BillDesk API error: {response.reason}")
        
        # BillDesk sends success response as JWS (signed)
        jws = response_text
        
        # Verify JWS -> get JWE
        jwe = verify_jws_payload(jws)
        
        # Decrypt JWE -> get actual JSON response
        decrypted_response = decrypt_payload(jwe)
        decoded_response = json.loads(decrypted_response)
        
        return {
            "success": True,
            "data": decoded_response,
            "trace_id": trace_id
        }

    

# Singleton instance
billdesk_util = BillDeskUtil()
