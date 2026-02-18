import qrcode
from io import BytesIO
import base64
from decimal import Decimal
from app.core.config import settings


def generate_upi_qr(amount: Decimal, order_id: str) -> str:
    upi_string = (
        f"upi://pay?"
        f"pa={settings.UPI_ID}&"
        f"pn={settings.UPI_NAME}&"
        f"am={float(amount):.2f}&"
        f"cu=INR&"
        f"tn=Order%20{order_id[:8]}"
    )
    
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(upi_string)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    buffer = BytesIO()
    img.save(buffer, format="PNG")
    img_base64 = base64.b64encode(buffer.getvalue()).decode()
    
    return f"data:image/png;base64,{img_base64}"


def get_upi_payment_info(amount: Decimal, order_id: str) -> dict:
    
    return {
        "upi_id": settings.UPI_ID,
        "upi_name": settings.UPI_NAME,
        "amount": float(amount),
        "order_id": order_id[:8].upper(),
        "qr_code": generate_upi_qr(amount, order_id),
        "instructions": [
            f"1. Scan the QR code with any UPI app (GPay, PhonePe, Paytm)",
            f"2. Verify amount: ₹{float(amount):.2f}",
            f"3. Complete the payment",
            f"4. Take a screenshot of payment confirmation",
            f"5. Upload screenshot below (optional but recommended)",
            f"6. Your order will be confirmed once payment is verified"
        ]
    }