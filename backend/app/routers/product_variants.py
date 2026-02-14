from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List

from app.core.database import get_db
from app.core.dependencies import require_role, CurrentUser
from app.models.product import Product
from app.models.product_variant import ProductVariant
from app.schemas.product_variant import ProductVariantCreate, ProductVariantUpdate, ProductVariantOut

router = APIRouter(prefix="/products", tags=["Product Variants"])


@router.get("/{product_id}/variants", response_model=List[ProductVariantOut])
def list_variants(
    product_id: UUID,
    db: Session = Depends(get_db),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    variants = db.query(ProductVariant).filter(
        ProductVariant.product_id == product_id,
        ProductVariant.is_active == True
    ).all()

    return variants


@router.post(
    "/{product_id}/variants",
    response_model=ProductVariantOut,
    status_code=status.HTTP_201_CREATED
)
def create_variant(
    product_id: UUID,
    variant_data: ProductVariantCreate,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    variant = ProductVariant(
        product_id=product_id,
        label=variant_data.label,
        price=variant_data.price,
        stock_quantity=variant_data.stock_quantity,
        is_active=variant_data.is_active,
    )

    db.add(variant)
    db.commit()
    db.refresh(variant)

    return variant


@router.put("/{product_id}/variants/{variant_id}", response_model=ProductVariantOut)
def update_variant(
    product_id: UUID,
    variant_id: UUID,
    variant_update: ProductVariantUpdate,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    variant = db.query(ProductVariant).filter(
        ProductVariant.id == variant_id,
        ProductVariant.product_id == product_id,
    ).first()

    if not variant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variant not found")

    if variant_update.label is not None:
        variant.label = variant_update.label
    if variant_update.price is not None:
        variant.price = variant_update.price
    if variant_update.stock_quantity is not None:
        variant.stock_quantity = variant_update.stock_quantity
    if variant_update.is_active is not None:
        variant.is_active = variant_update.is_active

    db.commit()
    db.refresh(variant)

    return variant


@router.delete("/{product_id}/variants/{variant_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_variant(
    product_id: UUID,
    variant_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    variant = db.query(ProductVariant).filter(
        ProductVariant.id == variant_id,
        ProductVariant.product_id == product_id,
    ).first()

    if not variant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variant not found")

    variant.is_active = False
    db.commit()

    return None
