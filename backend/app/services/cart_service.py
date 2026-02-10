from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from uuid import UUID
from typing import Dict

from app.models.cart import Cart, CartItem
from app.models.product import Product


def get_or_create_cart(db: Session, user_id: UUID) -> Cart:
    """
    Get existing cart for user or create a new one.
    
    Args:
        db: Database session
        user_id: User UUID
        
    Returns:
        Cart instance
    """
    cart = db.query(Cart).filter(Cart.user_id == user_id).first()
    
    if not cart:
        cart = Cart(user_id=user_id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    
    return cart


def add_item_to_cart(
    db: Session,
    user_id: UUID,
    product_id: UUID,
    quantity: int
) -> Cart:
   
    cart = get_or_create_cart(db, user_id)
    
    # Validate product exists and is active
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.is_active == True
    ).first()
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found or inactive"
        )
    
    existing_item = db.query(CartItem).filter(
        CartItem.cart_id == cart.id,
        CartItem.product_id == product_id
    ).first()
    
    new_quantity = quantity
    if existing_item:
        new_quantity = existing_item.quantity + quantity
    
    if product.stock_quantity < new_quantity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Insufficient stock. Available: {product.stock_quantity}, Requested: {new_quantity}"
        )
    
    if existing_item:
        existing_item.quantity = new_quantity
    else:
        cart_item = CartItem(
            cart_id=cart.id,
            product_id=product_id,
            quantity=quantity
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cart item not found"
        )
    
    product = db.query(Product).filter(Product.id == cart_item.product_id).first()
    if product.stock_quantity < quantity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Insufficient stock. Available: {product.stock_quantity}"
        )
    
    cart_item.quantity = quantity
    db.commit()
    db.refresh(cart)
    
    return cart


def remove_cart_item(
    db: Session,
    user_id: UUID,
    cart_item_id: UUID
) -> Cart:
    
    cart = get_or_create_cart(db, user_id)
    
    cart_item = db.query(CartItem).filter(
        CartItem.id == cart_item_id,
        CartItem.cart_id == cart.id
    ).first()
    
    if not cart_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cart item not found"
        )
    
    db.delete(cart_item)
    db.commit()
    db.refresh(cart)
    
    return cart


def clear_cart(db: Session, user_id: UUID) -> None:

    cart = get_or_create_cart(db, user_id)
    
    db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()
    db.commit()


def build_cart_response(db: Session, cart: Cart) -> Dict:
    cart = db.query(Cart).options(
        joinedload(Cart.items).joinedload(CartItem.product)
    ).filter(Cart.id == cart.id).first()
    
    items_out = []
    total_amount = 0.0

    for item in cart.items:
        unit_price = float(item.product.price)
        line_total = unit_price * item.quantity
        total_amount += line_total

        items_out.append({
            "id": item.id,
            "product_id": item.product_id,
            "quantity": item.quantity,
            "unit_price": unit_price,
            "line_total": line_total,
        })

    return {
        "id": cart.id,
        "items": items_out,
        "total_amount": total_amount,
    }