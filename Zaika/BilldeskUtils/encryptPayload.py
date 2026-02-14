import os
import json
import base64
from dotenv import load_dotenv
from jwcrypto import jwk, jwe


def encrypt_payload(payload):
    """
    Encrypts the data using the encryption key in A256GCM algorithm (JWE compact format)
    Uses keys from environment variables
    
    Args:
        payload: The plaintext payload to encrypt (str, bytes, or dict)
    
    Returns:
        str: JWE compact string
    """
    # Load environment variables
    load_dotenv()
    
    client_id = os.getenv("BILLDESK_CLIENT_ID")
    encryption_key = os.getenv("BILLDESK_ENCRYPTION_KEY")
    encryption_key_id = os.getenv("BILLDESK_KEY_ID")
    
    if not client_id or not encryption_key or not encryption_key_id:
        raise ValueError("Missing BILLDESK_CLIENT_ID, BILLDESK_ENCRYPTION_KEY, or BILLDESK_KEY_ID in environment")
    
    # Ensure key is base64url encoded
    key_b64url = base64.urlsafe_b64encode(encryption_key.encode('utf-8')).decode('utf-8').rstrip('=')
    
    # Create JWK for symmetric key
    key_dict = {
        "kty": "oct",
        "k": key_b64url,
        "alg": "A256GCM",
        "kid": encryption_key_id
    }
    key = jwk.JWK(**key_dict)
    
    # Prepare the input payload
    if isinstance(payload, bytes):
        plaintext = payload
    elif isinstance(payload, dict):
        plaintext = json.dumps(payload).encode('utf-8')
    else:
        plaintext = str(payload).encode('utf-8')
    
    # Create protected header
    protected_header = {
        "alg": "dir",
        "enc": "A256GCM",
        "kid": encryption_key_id,
        "clientid": client_id
    }
    
    # Create and encrypt JWE
    jwe_token = jwe.JWE(plaintext, recipient=key, protected=protected_header)
    
    # Return compact serialization
    return jwe_token.serialize(compact=True)