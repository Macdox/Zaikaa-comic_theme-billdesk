import os
import base64
from dotenv import load_dotenv
from jwcrypto import jwk, jws


def sign_payload(payload):
    """
    Signs the payload using HMAC-SHA256 (JWS compact format) with BillDesk keys from environment
    
    Args:
        payload: The payload to sign (usually encrypted JWE string) - str or bytes
    
    Returns:
        str: JWS compact string
    """
    # Load environment variables
    load_dotenv()
    
    client_id = os.getenv("BILLDESK_CLIENT_ID")
    signing_key = os.getenv("BILLDESK_SIGNING_KEY")
    signing_key_id = os.getenv("BILLDESK_KEY_ID")
    
    if not client_id or not signing_key or not signing_key_id:
        raise ValueError("Missing BILLDESK_CLIENT_ID, BILLDESK_SIGNING_KEY, or BILLDESK_KEY_ID in environment")
    
    # Ensure key is base64url encoded
    key_b64url = base64.urlsafe_b64encode(signing_key.encode('utf-8')).decode('utf-8').rstrip('=')
    
    # Create JWK for symmetric key
    key_dict = {
        "kty": "oct",
        "k": key_b64url,
        "alg": "HS256",
        "kid": signing_key_id
    }
    key = jwk.JWK(**key_dict)
    
    # Prepare the payload
    if isinstance(payload, bytes):
        plaintext = payload
    else:
        plaintext = str(payload).encode('utf-8')
    
    # Create protected header
    protected_header = {
        "alg": "HS256",
        "kid": signing_key_id,
        "clientid": client_id
    }
    
    # Create and sign JWS
    jws_token = jws.JWS(plaintext)
    jws_token.add_signature(key, alg="HS256", protected=protected_header)
    
    # Return compact serialization
    return jws_token.serialize(compact=True)
