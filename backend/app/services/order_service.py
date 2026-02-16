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

            for item in cart.items:
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

                if product.stock_quantity < item.quantity:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"Insufficient stock for {product.name}. Available: {product.stock_quantity}"
                    )

                product.stock_quantity -= item.quantity

                unit_price = product.price
                line_total = unit_price * item.quantity
                total_amount += line_total

                order_items.append(
                    OrderItem(
                        product_id=item.product_id,
                        quantity=item.quantity,
                        unit_price=unit_price,
                        line_total=line_total,
                    )
                )

            order = Order(
                user_id=user_id,
                total_amount=total_amount,
                status="PENDING",
                items=order_items,
            )

            db.add(order)

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
    """
    order = db.query(Order).filter(Order.id == order_id).first()

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )

    if user_id is not None and order.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this order"
        )

    validate_transition(order.status, new_status)

    order.status = new_status
    db.commit()
    db.refresh(order)

    return order


def get_user_orders(
    db: Session,
    user_id: UUID,
    skip: int = 0,
    limit: int = 50
) -> List[Order]:
    """
    Get paginated list of a specific user's orders.
    """
    return (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.user_id == user_id)
        .order_by(Order.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_all_orders(
    db: Session,
    skip: int = 0,
    limit: int = 50
) -> List[Order]:
    """
    Get ALL orders across all users — for admin only.
    """
    return (
        db.query(Order)
        .options(joinedload(Order.items))
        .order_by(Order.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_order_by_id(
    db: Session,
    order_id: UUID,
    user_id: UUID | None = None
) -> Order:
    """
    Get order by ID. Pass user_id=None to bypass ownership check (admin).
    """
    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )

    if user_id is not None and order.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this order"
        )

    return order