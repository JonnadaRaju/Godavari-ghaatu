from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, Numeric, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.core.database import Base


class Product(Base):
    
    __tablename__ = "products"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    price = Column(
        Numeric(10, 2),
        nullable=False,
        comment="Base price — use variant prices when variants exist"
    )

    stock_quantity = Column(
        Integer,
        nullable=False,
        default=0,
        comment="Base stock — use variant stock when variants exist"
    )
    
    image_url = Column(String(500), nullable=True, comment="Product image URL")
    category = Column(
        String(50), 
        nullable=False, 
        default="pickle",
        comment="Product category: pickle, spice, laddu, combo"
    )
    is_veg = Column(
        Boolean,
        nullable=False,
        default=True,
        comment="True for vegetarian products"
    )
    is_bestseller = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Mark as bestseller for homepage featured section"
    )
    is_new_arrival = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Mark as new arrival for marketing"
    )
    
    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    variants = relationship(
        "ProductVariant",
        back_populates="product",
        cascade="all, delete-orphan",
    )
    
    __table_args__ = (
        CheckConstraint("price > 0", name="ck_product_price_positive"),
        CheckConstraint("stock_quantity >= 0", name="ck_product_stock_non_negative"),
    )
    
    # Relationships
    combo_items = relationship(
        "ComboItem",
        foreign_keys="ComboItem.combo_product_id",
        back_populates="combo_product",
        cascade="all, delete-orphan",
    )
    
    component_items = relationship(
        "ComboItem",
        foreign_keys="ComboItem.component_product_id",
        back_populates="component_product",
    )
    
    reviews = relationship(
        "Review", back_populates="product", 
        cascade="all, delete-orphan",
    )


    def __repr__(self):
        return f"<Product(id={self.id}, name={self.name}, category={self.category}, is_veg={self.is_veg})>"