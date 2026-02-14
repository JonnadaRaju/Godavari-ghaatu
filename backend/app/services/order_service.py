from sqlalchemy.orm import Session, joinedload
from sqlalchemy import select
from fastapi import HTTPException, status
from uuid import UUID
from typing import List

from app.models.cart import Cart, CartItem
from app.models.product import Product
from app.models.product_variant import ProductVariant
from app.models.order import Order, OrderItem
from app.services.order_state import validate_transition


def create_order_from_cart(db: Session, user_id: UUID) -> Order:
    try:
        with db.begin_nested():
            # Lock cart row
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
                # Lock and validate product
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
                        detail=f"Product '{product.name}' is no longer available"
                    )

                # Day 3: handle variant vs base product
                variant_id = item.variant_id
                variant_label = None

                if variant_id:
                    # Lock and validate variant
                    variant = (
                        db.query(ProductVariant)
                        .filter(ProductVariant.id == variant_id)
                        .with_for_update()
                        .first()
                    )
                    if not variant or not variant.is_active:
                        raise HTTPException(
                            status_code=status.HTTP_409_CONFLICT,
                            detail=f"Variant for '{product.name}' is no longer available"
                        )
                    if variant.stock_quantity < item.quantity:
                        raise HTTPException(
                            status_code=status.HTTP_409_CONFLICT,
                            detail=f"Insufficient stock for '{product.name} - {variant.label}'. "
                                   f"Available: {variant.stock_quantity}"
                        )

                    # Deduct variant stock
                    variant.stock_quantity -= item.quantity

                    # Snapshot variant price and label
                    unit_price = variant.price
                    variant_label = variant.label

                else:
                    # No variant — use base product stock and price
                    if product.stock_quantity < item.quantity:
                        raise HTTPException(
                            status_code=status.HTTP_409_CONFLICT,
                            detail=f"Insufficient stock for '{product.name}'. "
                                   f"Available: {product.stock_quantity}"
                        )

                    # Deduct product stock
                    product.stock_quantity -= item.quantity
                    unit_price = product.price

                line_total = unit_price * item.quantity
                total_amount += line_total

                order_items.append(
                    OrderItem(
                        product_id=item.product_id,
                        variant_id=variant_id,          # Day 3
                        variant_label=variant_label,    # Day 3 snapshot
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
            db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()

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
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    if user_id is not None and order.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to update this order")

    validate_transition(order.status, new_status)

    order.status = new_status
    db.commit()
    db.refresh(order)
    return order


def get_user_orders(db: Session, user_id: UUID, skip: int = 0, limit: int = 10) -> List[Order]:
    return db.query(Order)\
        .filter(Order.user_id == user_id)\
        .order_by(Order.created_at.desc())\
        .offset(skip)\
        .limit(limit)\
        .all()


def get_order_by_id(db: Session, order_id: UUID, user_id: UUID | None = None) -> Order:
    order = db.query(Order)\
        .options(joinedload(Order.items))\
        .filter(Order.id == order_id)\
        .first()

    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    if user_id is not None and order.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to view this order")

    return order