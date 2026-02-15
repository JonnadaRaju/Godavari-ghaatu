from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from uuid import UUID
from typing import List
from pydantic import BaseModel, Field

from app.core.database import get_db
from app.core.dependencies import require_role, CurrentUser
from app.models.combo_item import ComboItem
from app.models.product import Product


class ComboItemAddIn(BaseModel):
    component_product_id: UUID = Field(..., description="Product ID to add as component")
    quantity: int = Field(..., gt=0, description="How many units of this component in the combo")


class ComboItemUpdateIn(BaseModel):
    quantity: int = Field(..., gt=0, description="Updated quantity")


class ComboItemOut(BaseModel):
    id: UUID
    combo_product_id: UUID
    component_product_id: UUID
    quantity: int
    component_name: str
    component_price: float
    component_image_url: str | None = None

    class Config:
        from_attributes = True



router = APIRouter(prefix="/products", tags=["Combo Management"])


@router.get("/{product_id}/combo-items", response_model=List[ComboItemOut])
def list_combo_items(
    product_id: UUID,
    db: Session = Depends(get_db),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    if product.category != "combo":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This product is not a combo")

    items = (
        db.query(ComboItem)
        .options(joinedload(ComboItem.component_product))
        .filter(ComboItem.combo_product_id == product_id)
        .all()
    )

    return [
        ComboItemOut(
            id=item.id,
            combo_product_id=item.combo_product_id,
            component_product_id=item.component_product_id,
            quantity=item.quantity,
            component_name=item.component_product.name,
            component_price=float(item.component_product.price),
            component_image_url=item.component_product.image_url,
        )
        for item in items
    ]


@router.post("/{product_id}/combo-items", response_model=ComboItemOut, status_code=status.HTTP_201_CREATED)
def add_combo_item(
    product_id: UUID,
    payload: ComboItemAddIn,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    combo = db.query(Product).filter(Product.id == product_id).first()
    if not combo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Combo product not found")
    if combo.category != "combo":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Product is not a combo")

    component = db.query(Product).filter(
        Product.id == payload.component_product_id,
        Product.is_active == True
    ).first()
    if not component:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Component product not found")

    if payload.component_product_id == product_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A combo cannot contain itself")

    existing = db.query(ComboItem).filter(
        ComboItem.combo_product_id == product_id,
        ComboItem.component_product_id == payload.component_product_id,
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Component already in combo")

    item = ComboItem(
        combo_product_id=product_id,
        component_product_id=payload.component_product_id,
        quantity=payload.quantity,
    )
    db.add(item)
    db.commit()
    db.refresh(item)

    return ComboItemOut(
        id=item.id,
        combo_product_id=item.combo_product_id,
        component_product_id=item.component_product_id,
        quantity=item.quantity,
        component_name=component.name,
        component_price=float(component.price),
        component_image_url=component.image_url,
    )


@router.put("/{product_id}/combo-items/{item_id}", response_model=ComboItemOut)
def update_combo_item(
    product_id: UUID,
    item_id: UUID,
    payload: ComboItemUpdateIn,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    item = db.query(ComboItem).options(joinedload(ComboItem.component_product)).filter(
        ComboItem.id == item_id,
        ComboItem.combo_product_id == product_id,
    ).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Combo item not found")

    item.quantity = payload.quantity
    db.commit()
    db.refresh(item)

    return ComboItemOut(
        id=item.id,
        combo_product_id=item.combo_product_id,
        component_product_id=item.component_product_id,
        quantity=item.quantity,
        component_name=item.component_product.name,
        component_price=float(item.component_product.price),
        component_image_url=item.component_product.image_url,
    )


@router.delete("/{product_id}/combo-items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_combo_item(
    product_id: UUID,
    item_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    item = db.query(ComboItem).filter(
        ComboItem.id == item_id,
        ComboItem.combo_product_id == product_id,
    ).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Combo item not found")

    db.delete(item)
    db.commit()
    return None