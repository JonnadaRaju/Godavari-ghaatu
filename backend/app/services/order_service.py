from sqlalchemy.orm import Session, joinedload
from sqlalchemy import select
from fastapi import HTTPException, status
from uuid import UUID
from typing import List
from decimal import Decimal

from app.models.cart import Cart, CartItem
from app.models.product import Product
from app.models.product_variant import ProductVariant
from app.models.order import Order, OrderItem
from app.services.order_state import validate_transition

FREE_DELIVERY_THRESHOLD = Decimal("500.00")
DELIVERY_CHARGE        = Decimal("50.00")
TAX_RATE               = Decimal("0.05")


def _calculate_charges(subtotal: Decimal):
    delivery_charge = Decimal("0") if subtotal >= FREE_DELIVERY_THRESHOLD else DELIVERY_CHARGE
    tax_amount      = (subtotal * TAX_RATE).quantize(Decimal("0.01"))
    total_amount    = subtotal + delivery_charge + tax_amount
    return delivery_charge, tax_amount, total_amount


def create_order_from_cart(db: Session, user_id: UUID) -> Order:
    try:
        with db.begin_nested():
            cart = (
                db.execute(
                    select(Cart)
                    .where(Cart.user_id == user_id)
                    .with_for_update()
                )
                .scalar_one_or_none()
            )

            if not cart or not cart.items:
                raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Cart is empty")

            order_items = []
            subtotal = Decimal("0")

            for item in cart.items:
                product = (
                    db.query(Product)
                    .filter(Product.id == item.product_id)
                    .with_for_update()
                    .first()
                )
                if not product:
                    raise HTTPException(status_code=404, detail=f"Product {item.product_id} not found")
                if not product.is_active:
                    raise HTTPException(status_code=409, detail=f"Product '{product.name}' is no longer available")

                variant_id    = item.variant_id
                variant_label = None

                if variant_id:
                    variant = (
                        db.query(ProductVariant)
                        .filter(ProductVariant.id == variant_id)
                        .with_for_update()
                        .first()
                    )
                    if not variant or not variant.is_active:
                        raise HTTPException(status_code=409, detail=f"Variant for '{product.name}' is unavailable")
                    if variant.stock_quantity < item.quantity:
                        raise HTTPException(
                            status_code=409,
                            detail=f"Insufficient stock for '{product.name} - {variant.label}'. Available: {variant.stock_quantity}"
                        )
                    variant.stock_quantity -= item.quantity
                    unit_price    = variant.price
                    variant_label = variant.label
                else:
                    if product.stock_quantity < item.quantity:
                        raise HTTPException(
                            status_code=409,
                            detail=f"Insufficient stock for '{product.name}'. Available: {product.stock_quantity}"
                        )
                    product.stock_quantity -= item.quantity
                    unit_price = product.price

                line_total = unit_price * item.quantity
                subtotal  += Decimal(str(line_total))

                order_items.append(
                    OrderItem(
                        product_id    = item.product_id,
                        variant_id    = variant_id,
                        variant_label = variant_label,
                        quantity      = item.quantity,
                        unit_price    = unit_price,
                        line_total    = line_total,
                    )
                )

            delivery_charge, tax_amount, total_amount = _calculate_charges(subtotal)

            order = Order(
                user_id         = user_id,
                subtotal        = subtotal,
                delivery_charge = delivery_charge,
                tax_amount      = tax_amount,
                total_amount    = total_amount,
                status          = "PENDING",
                items           = order_items,
            )
            db.add(order)
            db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()

        db.commit()
        db.refresh(order)
        return order

    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create order: {str(e)}")


def update_order_status(
    db: Session, order_id: UUID, user_id: UUID | None, new_status: str
) -> Order:
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if user_id is not None and order.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this order")

    validate_transition(order.status, new_status)
    order.status = new_status
    db.commit()
    db.refresh(order)
    return order


def get_user_orders(
    db: Session, user_id: UUID, skip: int = 0, limit: int = 100
) -> List[Order]:
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
    db: Session, skip: int = 0, limit: int = 100
) -> List[Order]:
    return (
        db.query(Order)
        .options(joinedload(Order.items))
        .order_by(Order.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_order_by_id(
    db: Session, order_id: UUID, user_id: UUID | None = None
) -> Order:
    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if user_id is not None and order.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to view this order")
    return order