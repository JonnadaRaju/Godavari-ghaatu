from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role, CurrentUser
from app.services.upi_service import get_upi_payment_info
from app.models.order import Order

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.get("/upi/{order_id}")
def get_upi_info(
    order_id: UUID,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):

    order = db.query(Order).filter(Order.id == order_id).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.user_id != user.user_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    if order.status != "PENDING":
        raise HTTPException(
            status_code=400, 
            detail=f"Cannot generate payment for order with status {order.status}"
        )
    
    return get_upi_payment_info(order.total_amount, str(order.id))


@router.post("/upi/{order_id}/upload-screenshot")
async def upload_payment_screenshot(
    order_id: UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):

    order = db.query(Order).filter(Order.id == order_id).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.user_id != user.user_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    
    return {
        "message": "Screenshot uploaded successfully. Payment will be verified shortly.",
        "order_id": str(order_id),
        "filename": file.filename,
    }


@router.post("/verify/{order_id}")
def verify_payment(
    order_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.status != "PENDING":
        raise HTTPException(
            status_code=400,
            detail=f"Order is already {order.status}"
        )
    
    order.status = "PAID"
    db.commit()
    db.refresh(order)
    
    return {
        "message": "Payment verified successfully",
        "order_id": str(order_id),
        "status": "PAID"
    }