import os
import json
import base64
from dotenv import load_dotenv
from jwcrypto import jwk, jws, jwe


def verify_jws_payload(jws_token):
    """
    Verifies and decodes a JWS (signed JWT) using BillDesk signing key from environment
    
    Args:
        jws_token: The JWS compact string to verify and decode
    
    Returns:
        The decoded payload as a dict if valid JSON, otherwise raw string
    """
    # Load environment variables
    load_dotenv()
    
    signing_key = os.getenv("BILLDESK_SIGNING_KEY", "GFSgVvMFWwrVXmH03ynU57sQeoh49PGE")
    signing_key_id = os.getenv("BILLDESK_KEY_ID", "HMAC")
    
    print(signing_key, signing_key_id)
    
    if not signing_key or not signing_key_id:
        raise ValueError("Missing BILLDESK_SIGNING_KEY or BILLDESK_KEY_ID in environment")
    
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
    
    # Verify the JWS
    jws_obj = jws.JWS()
    jws_obj.deserialize(jws_token)
    jws_obj.verify(key)
    
    # Get the payload
    raw = jws_obj.payload.decode('utf-8')
    
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        print(f"Payload is not valid JSON. Raw payload: {raw}")
        return raw


def decrypt_payload(jwe_token):
    """
    Decrypts a JWE payload using BillDesk keys from environment
    
    Args:
        jwe_token: The JWE compact string to decrypt
    
    Returns:
        str: The decrypted plaintext (JSON string)
    """
    # Load environment variables
    load_dotenv()
    
    encryption_key = os.getenv("BILLDESK_ENCRYPTION_KEY", "RcnT73n4W28UOMWtpX0BFXpin8y9hZ3I")
    encryption_key_id = os.getenv("BILLDESK_KEY_ID", "xvxH6ROBi6Pg")
    
    if not encryption_key or not encryption_key_id:
        raise ValueError("Missing BILLDESK_ENCRYPTION_KEY or BILLDESK_KEY_ID in environment")
    
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
    
    # Decrypt the JWE
    jwe_obj = jwe.JWE()
    jwe_obj.deserialize(jwe_token)
    jwe_obj.decrypt(key)
    
    return jwe_obj.payload.decode('utf-8')
