from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.cart import Cart, CartItem


def get_or_create_cart(db: Session, user_id):
    cart = db.query(Cart).filter_by(user_id=user_id).first()

    if not cart:
        cart = Cart(user_id=user_id)
        db.add(cart)
        db.flush()  # get cart.id without commit

    return cart


def add_item_to_cart(db: Session, user_id, product_id, quantity):
    if quantity <= 0:
        raise ValueError("Quantity must be greater than zero")

    cart = get_or_create_cart(db, user_id)

    item = (
        db.query(CartItem)
        .filter_by(cart_id=cart.id, product_id=product_id)
        .first()
    )

    if item:
        item.quantity += quantity
    else:
        item = CartItem(
            cart_id=cart.id,
            product_id=product_id,
            quantity=quantity,
        )
        db.add(item)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise

    db.refresh(cart)
    return cart