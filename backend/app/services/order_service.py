from sqlalchemy.orm import Session, joinedload
from sqlalchemy import select
from fastapi import HTTPException, status
from uuid import UUID
from typing import List

from app.models.cart import Cart, CartItem
from app.models.product import Product
from app.models.order import Order, OrderItem
from app.services.order_state import validate_transition


def create_order_from_cart(db: Session, user_id: UUID) -> Order:
    """
    Create order from user's cart and clear cart.
    
    Args:
        db: Database session
        user_id: User UUID
        
    Returns:
        Created Order instance
        
    Raises:
        HTTPException: If cart is empty or insufficient stock
    """
    try:
        with db.begin_nested():
            # Get cart with lock
            cart = (
                db.execute(
                    select(Cart)
                    .where(Cart.user_id == user_id)
                    .with_for_update()
                )
                .scalar_one_or_none()
            )

            if not cart or not cart.items:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Cart is empty",
                )

            order_items = []
            total_amount = 0

            # Process each cart item
            for item in cart.items:
                # Get product with lock to prevent race conditions
                product = (
                    db.query(Product)
                    .filter(Product.id == item.product_id)
                    .with_for_update()
                    .first()
                )
                
                if not product:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Product {item.product_id} not found"
                    )
                
                if not product.is_active:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"Product {product.name} is no longer available"
                    )
                
                # Validate stock
                if product.stock_quantity < item.quantity:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"Insufficient stock for {product.name}. Available: {product.stock_quantity}"
                    )
                
                # Deduct stock
                product.stock_quantity -= item.quantity

                # Calculate pricing
                unit_price = product.price
                line_total = unit_price * item.quantity
                total_amount += line_total

                # Create order item
                order_items.append(
                    OrderItem(
                        product_id=item.product_id,
                        quantity=item.quantity,
                        unit_price=unit_price,
                        line_total=line_total,
                    )
                )

            # Create order
            order = Order(
                user_id=user_id,
                total_amount=total_amount,
                status="PENDING",
                items=order_items,
            )

            db.add(order)

            # Clear cart
            db.query(CartItem).filter(
                CartItem.cart_id == cart.id
            ).delete()

        db.commit()
        db.refresh(order)
        return order

    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create order: {str(e)}"
        )


def update_order_status(
    db: Session,
    order_id: UUID,
    user_id: UUID | None,
    new_status: str
) -> Order:
    """
    Update order status with state transition validation.
    
    Args:
        db: Database session
        order_id: Order UUID
        user_id: User UUID (None for service bypass)
        new_status: New status to set
        
    Returns:
        Updated Order instance
        
    Raises:
        HTTPException: If order not found, unauthorized, or invalid transition
    """
    order = db.query(Order).filter(Order.id == order_id).first()
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    # Verify ownership (unless service bypass with user_id=None)
    if user_id is not None and order.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this order"
        )
    
    # Validate state transition
    validate_transition(order.status, new_status)
    
    # Update status
    order.status = new_status
    db.commit()
    db.refresh(order)
    
    return order


def get_user_orders(
    db: Session,
    user_id: UUID,
    skip: int = 0,
    limit: int = 10
) -> List[Order]:
    """
    Get paginated list of user's orders.
    
    Args:
        db: Database session
        user_id: User UUID
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List of Order instances
    """
    orders = db.query(Order)\
        .filter(Order.user_id == user_id)\
        .order_by(Order.created_at.desc())\
        .offset(skip)\
        .limit(limit)\
        .all()
    
    return orders


def get_order_by_id(
    db: Session,
    order_id: UUID,
    user_id: UUID | None = None
) -> Order:
    """
    Get order by ID with optional user verification.
    
    Args:
        db: Database session
        order_id: Order UUID
        user_id: Optional User UUID for ownership verification
        
    Returns:
        Order instance with items loaded
        
    Raises:
        HTTPException: If order not found or unauthorized
    """
    order = db.query(Order)\
        .options(joinedload(Order.items))\
        .filter(Order.id == order_id)\
        .first()
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    # Verify ownership if user_id provided
    if user_id is not None and order.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this order"
        )
    
    return order