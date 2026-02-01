from sqlalchemy.orm import Session
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.cart import Cart, CartItem
from app.models.product import Product
from app.models.order import Order, OrderItem


def create_order_from_cart(db: Session, user_id):
    try:
        with db.begin():

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
                    .first()
                )

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
                items=order_items,
            )

            db.add(order)

            db.query(CartItem).filter(
                CartItem.cart_id == cart.id
            ).delete()

        return order

    except Exception:
        db.rollback()
        raise
