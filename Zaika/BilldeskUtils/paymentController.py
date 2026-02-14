import os
import json
import secrets
import logging
from datetime import datetime, timezone, timedelta
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.db import connection
from dotenv import load_dotenv

from .billdeskUtils import billdesk_util
from .decryptPaylaod import verify_jws_payload, decrypt_payload

load_dotenv()
logger = logging.getLogger(__name__)


def get_user_from_session(request):
    """Get user details from session"""
    if not request.session.get("is_authenticated"):
        return None
    return {
        "id": request.session.get("user_id"),
        "name": request.session.get("user_name"),
        "email": request.session.get("user_email"),
        "phone": request.session.get("user_phone")
    }


def create_order_payload(order_id, amount, currency, customer_name, customer_email, 
                         customer_phone, return_url, additional_info=None):
    """Create BillDesk order payload"""
    merchant_id = os.getenv("BILLDESK_MERCHANT_ID")
    client_id = os.getenv("BILLDESK_CLIENT_ID")
    
    payload = {
        "mercid": merchant_id,
        "orderid": order_id,
        "amount": str(amount),
        "order_date": datetime.now(timezone(timedelta(hours=5, minutes=30))).strftime("%Y-%m-%dT%H:%M:%S+05:30"),
        "currency": currency,
        "ru": return_url,
        "additional_info": additional_info or {},
        "itemcode": "DIRECT",
        "device": {
            "init_channel": "internet",
            "ip": additional_info.get("ip", "127.0.0.1") if additional_info else "127.0.0.1",
            "user_agent": additional_info.get("user_agent", "") if additional_info else "",
            "accept_header": "text/html",
            "fingerprintid": "",
            "browser_tz": "-330",
            "browser_color_depth": "32",
            "browser_java_enabled": "false",
            "browser_screen_height": "768",
            "browser_screen_width": "1366",
            "browser_language": "en-US",
            "browser_javascript_enabled": "true"
        }
    }
    
    return payload


@csrf_exempt
@require_http_methods(["POST"])
def create_payment_order(request):
    """
    Create a new payment order for BillDesk
    POST /api/payment/create-order
    """
    try:
        user = get_user_from_session(request)
        if not user:
            return JsonResponse({"success": False, "message": "Authentication required"}, status=401)
        
        data = json.loads(request.body)
        order_id = data.get("orderId")
        
        if not order_id:
            return JsonResponse({"success": False, "message": "Order ID is required"}, status=400)
        
        # Validate BillDesk configuration
        try:
            billdesk_util.validate_config()
        except ValueError as config_error:
            logger.error(f"BillDesk config error: {config_error}")
            return JsonResponse({
                "success": False,
                "message": "Payment gateway not configured properly",
                "code": "PAYMENT_CONFIG_ERROR"
            }, status=500)
        
        # Find the order from database
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT order_id, user_id, amount, currency, status, event_id, team_id
                FROM orders WHERE order_id = %s AND user_id = %s
            """, [order_id, user["id"]])
            order_row = cursor.fetchone()
        
        if not order_row:
            return JsonResponse({"success": False, "message": "Order not found"}, status=404)
        
        order = {
            "order_id": order_row[0],
            "user_id": order_row[1],
            "amount": order_row[2],
            "currency": order_row[3] or "356",  # Default to INR
            "status": order_row[4],
            "event_id": order_row[5],
            "team_id": order_row[6]
        }
        
        # Check order status
        if order["status"] == "PAID":
            return JsonResponse({"success": False, "message": "Order already paid"}, status=400)
        
        if order["status"] == "FAILED":
            return JsonResponse({
                "success": False, 
                "message": "Order has failed. Please create a new registration."
            }, status=400)
        
        # Generate return URL
        backend_url = os.getenv("BACKEND_URL", "http://localhost:8000")
        return_url = f"{backend_url}/api/payments/response"
        
        # Create BillDesk order payload
        order_payload = create_order_payload(
            order_id=order["order_id"],
            amount=order["amount"],
            currency=order["currency"],
            customer_name=user["name"],
            customer_email=user["email"],
            customer_phone=user.get("phone", ""),
            return_url=return_url,
            additional_info={
                "event_id": str(order.get("event_id", "")),
                "user_id": str(user["id"]),
                "team_id": str(order.get("team_id", "")),
                "ip": get_client_ip(request),
                "user_agent": request.META.get("HTTP_USER_AGENT", "")
            }
        )
        
        # Create transaction record
        transaction_id = f"TXN_{order_id}_{int(datetime.now().timestamp() * 1000)}"
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO transactions 
                (transaction_id, order_id, user_id, amount, currency, status, 
                 request_payload, ip_address, user_agent, initiated_at, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, [
                transaction_id,
                order_id,
                user["id"],
                order["amount"],
                order["currency"],
                "INITIATED",
                json.dumps(order_payload),
                get_client_ip(request),
                request.META.get("HTTP_USER_AGENT", ""),
                datetime.now(),
                datetime.now()
            ])
        
        # Log payment initiation
        logger.info(f"Payment initiated: order_id={order_id}, transaction_id={transaction_id}, amount={order['amount']}")
        
        # Make API call to BillDesk
        try:
            billdesk_response = billdesk_util.create_order(order_payload)
        except Exception as bd_error:
            logger.error(f"BillDesk API error: {bd_error}")
            
            # Update transaction status
            with connection.cursor() as cursor:
                cursor.execute("""
                    UPDATE transactions SET status = %s, error_message = %s 
                    WHERE transaction_id = %s
                """, ["FAILED", str(bd_error), transaction_id])
            
            return JsonResponse({
                "success": False,
                "message": "Payment gateway error. Please try again.",
                "code": "BILLDESK_API_ERROR"
            }, status=502)
        
        # Update order with BillDesk order ID
        bd_order_id = (billdesk_response.get("data", {}).get("bdorderid") or 
                       billdesk_response.get("data", {}).get("orderid") or 
                       order_id)
        
        with connection.cursor() as cursor:
            cursor.execute("""
                UPDATE orders SET status = %s, bd_order_id = %s WHERE order_id = %s
            """, ["PENDING", bd_order_id, order_id])
            
            cursor.execute("""
                UPDATE transactions SET bd_order_id = %s, bd_trace_id = %s 
                WHERE transaction_id = %s
            """, [bd_order_id, billdesk_response.get("trace_id"), transaction_id])
        
        # Get redirect URL from BillDesk response
        logger.info(f"BillDesk response: {billdesk_response.get('data')}")
        
        links = billdesk_response.get("data", {}).get("links", [])
        redirect_link = next((link for link in links if link.get("rel") == "redirect"), None)
        redirect_url = redirect_link.get("href") if redirect_link else None
        
        if not redirect_url:
            logger.error(f"No redirect URL in BillDesk response: {billdesk_response.get('data')}")
            return JsonResponse({
                "success": False,
                "message": "Invalid response from payment gateway",
                "code": "BILLDESK_NO_REDIRECT"
            }, status=502)
        
        # Extract redirect parameters
        parameters = redirect_link.get("parameters", {})
        merchantid = parameters.get("merchantid")
        bdorderid = parameters.get("bdorderid")
        rdata = parameters.get("rdata")
        
        logger.info(f"BillDesk redirect URL: {redirect_url}")
        
        return JsonResponse({
            "success": True,
            "message": "Payment order created",
            "data": {
                "orderId": order["order_id"],
                "bdOrderId": bd_order_id,
                "transactionId": transaction_id,
                "amount": order["amount"],
                "currency": order["currency"],
                "merchantid": os.getenv("BILLDESK_MERCHANT_ID"),
                "bdorderid": bdorderid,
                "rdata": rdata,
                "redirectUrl": redirect_url,
                "customerName": user["name"],
                "customerEmail": user["email"]
            }
        })
        
    except json.JSONDecodeError:
        return JsonResponse({"success": False, "message": "Invalid JSON"}, status=400)
    except Exception as error:
        logger.error(f"Error creating payment order: {error}")
        return JsonResponse({
            "success": False,
            "message": "Failed to create payment order"
        }, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def forward_to_billdesk(request):
    """
    Serve an auto-submit form that posts to BillDesk
    GET /api/payment/forward
    """
    try:
        merchantid = request.GET.get("merchantid")
        bdorderid = request.GET.get("bdorderid")
        rdata = request.GET.get("rdata")
        
        logger.info(f"Forwarding to BillDesk: merchantid={merchantid}, bdorderid={bdorderid}")
        
        if not merchantid or not bdorderid or not rdata:
            return HttpResponse("""
                <h2>Missing payment parameters</h2>
                <p>Please try again.</p>
            """, status=400)
        
        redirect_url = os.getenv("BILLDESK_REDIRECT_URL", "https://pay.billdesk.com/web/v1_2/embeddedsdk")
        
        # Generate CSP nonce
        nonce = secrets.token_urlsafe(16)
        
        html = f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Redirecting to BillDesk</title>
</head>
<body>
  <form id="sdklaunch" method="POST" action="{redirect_url}">
    <input type="hidden" name="merchantid" value="{merchantid}" />
    <input type="hidden" name="bdorderid" value="{bdorderid}" />
    <input type="hidden" name="rdata" value="{rdata}" />
  </form>

  <p>Redirecting to payment gateway...</p>

  <script nonce="{nonce}">
    document.getElementById('sdklaunch').submit();
  </script>
</body>
</html>
"""
        response = HttpResponse(html, content_type="text/html")
        response["Content-Security-Policy"] = f"script-src 'self' 'nonce-{nonce}'"
        return response
        
    except Exception as error:
        logger.error(f"Error in forward_to_billdesk: {error}")
        return HttpResponse("<h2>Payment redirection failed</h2>", status=500)


@csrf_exempt
@require_http_methods(["GET"])
def get_order_status(request, order_id):
    """
    Get order status
    GET /api/payment/order/<order_id>
    """
    try:
        user = get_user_from_session(request)
        if not user:
            return JsonResponse({"message": "Authentication required"}, status=401)
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT order_id, amount, currency, status, transaction_id, paid_at, created_at
                FROM orders WHERE order_id = %s AND user_id = %s
            """, [order_id, user["id"]])
            order_row = cursor.fetchone()
        
        if not order_row:
            return JsonResponse({"message": "Order not found"}, status=404)
        
        return JsonResponse({
            "success": True,
            "order": {
                "orderId": order_row[0],
                "amount": order_row[1],
                "currency": order_row[2],
                "status": order_row[3],
                "transactionId": order_row[4],
                "paidAt": order_row[5].isoformat() if order_row[5] else None,
                "createdAt": order_row[6].isoformat() if order_row[6] else None
            }
        })
        
    except Exception as error:
        logger.error(f"Error getting order status: {error}")
        return JsonResponse({"message": "Failed to get order status"}, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def get_payment_history(request):
    """
    Get user's payment history
    GET /api/payment/history
    """
    try:
        user = get_user_from_session(request)
        if not user:
            return JsonResponse({"message": "Authentication required"}, status=401)
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT order_id, amount, currency, status, transaction_id, paid_at, created_at
                FROM orders WHERE user_id = %s
                ORDER BY created_at DESC LIMIT 50
            """, [user["id"]])
            rows = cursor.fetchall()
        
        orders = [{
            "orderId": row[0],
            "amount": row[1],
            "currency": row[2],
            "status": row[3],
            "transactionId": row[4],
            "paidAt": row[5].isoformat() if row[5] else None,
            "createdAt": row[6].isoformat() if row[6] else None
        } for row in rows]
        
        return JsonResponse({"success": True, "orders": orders})
        
    except Exception as error:
        logger.error(f"Error getting payment history: {error}")
        return JsonResponse({"message": "Failed to get payment history"}, status=500)


@csrf_exempt
@require_http_methods(["POST"])
def retry_payment(request):
    """
    Retry failed payment
    POST /api/payment/retry
    """
    try:
        user = get_user_from_session(request)
        if not user:
            return JsonResponse({"message": "Authentication required"}, status=401)
        
        data = json.loads(request.body)
        order_id = data.get("orderId")
        
        if not order_id:
            return JsonResponse({"message": "Order ID is required"}, status=400)
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT order_id, status FROM orders WHERE order_id = %s AND user_id = %s
            """, [order_id, user["id"]])
            order_row = cursor.fetchone()
        
        if not order_row:
            return JsonResponse({"message": "Order not found"}, status=404)
        
        status = order_row[1]
        
        # Only allow retry for CREATED or FAILED orders
        if status not in ["CREATED", "FAILED"]:
            return JsonResponse({
                "message": f"Cannot retry order with status: {status}"
            }, status=400)
        
        # Reset order status
        with connection.cursor() as cursor:
            cursor.execute("""
                UPDATE orders SET status = %s, failed_at = NULL, failure_reason = NULL 
                WHERE order_id = %s
            """, ["CREATED", order_id])
        
        return JsonResponse({
            "success": True,
            "message": "Order ready for retry",
            "orderId": order_id
        })
        
    except json.JSONDecodeError:
        return JsonResponse({"message": "Invalid JSON"}, status=400)
    except Exception as error:
        logger.error(f"Error retrying payment: {error}")
        return JsonResponse({"message": "Failed to retry payment"}, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def get_all_transactions(request):
    """
    Get all transactions (Admin only)
    GET /api/payment/transactions
    """
    try:
        # TODO: Add admin authentication check
        
        status = request.GET.get("status")
        start_date = request.GET.get("startDate")
        end_date = request.GET.get("endDate")
        page = int(request.GET.get("page", 1))
        limit = int(request.GET.get("limit", 50))
        offset = (page - 1) * limit
        
        # Build query
        query = "SELECT * FROM transactions WHERE 1=1"
        params = []
        
        if status:
            query += " AND status = %s"
            params.append(status)
        
        if start_date:
            query += " AND created_at >= %s"
            params.append(start_date)
        
        if end_date:
            query += " AND created_at <= %s"
            params.append(end_date)
        
        query += " ORDER BY created_at DESC LIMIT %s OFFSET %s"
        params.extend([limit, offset])
        
        with connection.cursor() as cursor:
            cursor.execute(query, params)
            columns = [col[0] for col in cursor.description]
            rows = cursor.fetchall()
            
            # Get total count
            count_query = "SELECT COUNT(*) FROM transactions WHERE 1=1"
            count_params = []
            if status:
                count_query += " AND status = %s"
                count_params.append(status)
            if start_date:
                count_query += " AND created_at >= %s"
                count_params.append(start_date)
            if end_date:
                count_query += " AND created_at <= %s"
                count_params.append(end_date)
            
            cursor.execute(count_query, count_params)
            total = cursor.fetchone()[0]
        
        transactions = [dict(zip(columns, row)) for row in rows]
        
        # Serialize datetime objects
        for txn in transactions:
            for key, value in txn.items():
                if isinstance(value, datetime):
                    txn[key] = value.isoformat()
        
        return JsonResponse({
            "success": True,
            "transactions": transactions,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total,
                "totalPages": (total + limit - 1) // limit
            }
        })
        
    except Exception as error:
        logger.error(f"Error getting transactions: {error}")
        return JsonResponse({"message": "Failed to get transactions"}, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def get_transaction_details(request, transaction_id):
    """
    Get transaction details (Admin only)
    GET /api/payment/transaction/<transaction_id>
    """
    try:
        # TODO: Add admin authentication check
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT * FROM transactions WHERE transaction_id = %s
            """, [transaction_id])
            columns = [col[0] for col in cursor.description]
            row = cursor.fetchone()
        
        if not row:
            return JsonResponse({"message": "Transaction not found"}, status=404)
        
        transaction = dict(zip(columns, row))
        
        # Serialize datetime objects
        for key, value in transaction.items():
            if isinstance(value, datetime):
                transaction[key] = value.isoformat()
        
        return JsonResponse({"success": True, "transaction": transaction})
        
    except Exception as error:
        logger.error(f"Error getting transaction details: {error}")
        return JsonResponse({"message": "Failed to get transaction details"}, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def get_transaction_summary(request):
    """
    Get transaction summary/stats (Admin only)
    GET /api/payment/transactions/summary
    """
    try:
        # TODO: Add admin authentication check
        
        start_date = request.GET.get("startDate")
        end_date = request.GET.get("endDate")
        
        # Build query
        query = """
            SELECT status, COUNT(*) as count, COALESCE(SUM(amount), 0) as total_amount
            FROM transactions WHERE 1=1
        """
        params = []
        
        if start_date:
            query += " AND created_at >= %s"
            params.append(start_date)
        
        if end_date:
            query += " AND created_at <= %s"
            params.append(end_date)
        
        query += " GROUP BY status"
        
        with connection.cursor() as cursor:
            cursor.execute(query, params)
            rows = cursor.fetchall()
        
        # Format summary
        formatted = {
            "total": {"count": 0, "amount": 0},
            "success": {"count": 0, "amount": 0},
            "failed": {"count": 0, "amount": 0},
            "pending": {"count": 0, "amount": 0},
            "initiated": {"count": 0, "amount": 0}
        }
        
        for row in rows:
            status = (row[0] or "unknown").lower()
            count = row[1]
            amount = float(row[2] or 0)
            
            formatted["total"]["count"] += count
            formatted["total"]["amount"] += amount
            
            if status in formatted:
                formatted[status]["count"] = count
                formatted[status]["amount"] = amount
        
        return JsonResponse({
            "success": True,
            "summary": formatted,
            "dateRange": {
                "startDate": start_date,
                "endDate": end_date
            }
        })
        
    except Exception as error:
        logger.error(f"Error getting transaction summary: {error}")
        return JsonResponse({"message": "Failed to get transaction summary"}, status=500)


def get_client_ip(request):
    """Get client IP address from request"""
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "127.0.0.1")
