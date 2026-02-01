from sqlalchemy.orm import Session, joinedload

from app.models.cart import Cart
from app.models.product import Product


def build_cart_response(db: Session, cart: Cart):
    items_out = []
    total_amount = 0.0

    for item in cart.items:
        product = (
            db.query(Product)
            .filter(Product.id == item.product_id)
            .first()
        )

        unit_price = product.price
        line_total = unit_price * item.quantity
        total_amount += line_total

        items_out.append(
            {
                "id": item.id,
                "product_id": item.product_id,
                "quantity": item.quantity,
                "unit_price": unit_price,
                "line_total": line_total,
            }
        )

    return {
        "id": cart.id,
        "items": items_out,
        "total_amount": total_amount,
    }