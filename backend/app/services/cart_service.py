from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from uuid import UUID
from typing import Optional, Dict

from app.models.cart import Cart, CartItem
from app.models.product import Product
from app.models.product_variant import ProductVariant


def get_or_create_cart(db: Session, user_id: UUID) -> Cart:
    cart = db.query(Cart).filter(Cart.user_id == user_id).first()
    if not cart:
        cart = Cart(user_id=user_id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart


def _get_variant(db: Session, variant_id: UUID) -> ProductVariant:
    """Fetch and validate a variant exists and is active."""
    variant = db.query(ProductVariant).filter(
        ProductVariant.id == variant_id,
        ProductVariant.is_active == True
    ).first()
    if not variant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product variant not found or inactive"
        )
    return variant


def add_item_to_cart(
    db: Session,
    user_id: UUID,
    product_id: UUID,
    quantity: int,
    variant_id: Optional[UUID] = None,   # Day 3
) -> Cart:
    cart = get_or_create_cart(db, user_id)

    # Validate product
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.is_active == True
    ).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found or inactive"
        )

    # Day 3: Validate variant belongs to this product
    if variant_id:
        variant = _get_variant(db, variant_id)
        if variant.product_id != product_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Variant does not belong to this product"
            )
        available_stock = variant.stock_quantity
    else:
        available_stock = product.stock_quantity

    # Check if item already in cart (same product + same variant)
    existing_item = db.query(CartItem).filter(
        CartItem.cart_id == cart.id,
        CartItem.product_id == product_id,
        CartItem.variant_id == variant_id,
    ).first()

    new_quantity = quantity
    if existing_item:
        new_quantity = existing_item.quantity + quantity

    if available_stock < new_quantity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Insufficient stock. Available: {available_stock}, Requested: {new_quantity}"
        )

    if existing_item:
        existing_item.quantity = new_quantity
    else:
        cart_item = CartItem(
            cart_id=cart.id,
            product_id=product_id,
            variant_id=variant_id,
            quantity=quantity,
        )
        db.add(cart_item)

    db.commit()
    db.refresh(cart)
    return cart


def update_cart_item_quantity(
    db: Session,
    user_id: UUID,
    cart_item_id: UUID,
    quantity: int
) -> Cart:
    cart = get_or_create_cart(db, user_id)

    cart_item = db.query(CartItem).filter(
        CartItem.id == cart_item_id,
        CartItem.cart_id == cart.id
    ).first()
    if not cart_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")

    # Day 3: check variant stock or product stock
    if cart_item.variant_id:
        variant = db.query(ProductVariant).filter(ProductVariant.id == cart_item.variant_id).first()
        available_stock = variant.stock_quantity
    else:
        product = db.query(Product).filter(Product.id == cart_item.product_id).first()
        available_stock = product.stock_quantity

    if available_stock < quantity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Insufficient stock. Available: {available_stock}"
        )

    cart_item.quantity = quantity
    db.commit()
    db.refresh(cart)
    return cart


def remove_cart_item(db: Session, user_id: UUID, cart_item_id: UUID) -> Cart:
    cart = get_or_create_cart(db, user_id)

    cart_item = db.query(CartItem).filter(
        CartItem.id == cart_item_id,
        CartItem.cart_id == cart.id
    ).first()
    if not cart_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")

    db.delete(cart_item)
    db.commit()
    db.refresh(cart)
    return cart


def clear_cart(db: Session, user_id: UUID) -> None:
    cart = get_or_create_cart(db, user_id)
    db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()
    db.commit()


def build_cart_response(db: Session, cart: Cart) -> Dict:
    """Build cart response with computed unit_price and line_total."""
    cart = db.query(Cart).options(
        joinedload(Cart.items).joinedload(CartItem.product),
        joinedload(Cart.items).joinedload(CartItem.variant),  # Day 3
    ).filter(Cart.id == cart.id).first()

    items_out = []
    total_amount = 0.0

    for item in cart.items:
        # Day 3: use variant price if variant selected, else product base price
        if item.variant:
            unit_price = float(item.variant.price)
            variant_label = item.variant.label
        else:
            unit_price = float(item.product.price)
            variant_label = None

        line_total = unit_price * item.quantity
        total_amount += line_total

        items_out.append({
            "id": item.id,
            "product_id": item.product_id,
            "variant_id": item.variant_id,         # Day 3
            "variant_label": variant_label,          # Day 3
            "quantity": item.quantity,
            "unit_price": unit_price,
            "line_total": line_total,
        })

    return {
        "id": cart.id,
        "items": items_out,
        "total_amount": total_amount,
    }