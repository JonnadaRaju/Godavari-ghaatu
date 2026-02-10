from sqlalchemy import Column, Integer, String, Numeric, Boolean, CheckConstraint, Text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from app.core.database import Base


class Product(Base):
    
    __tablename__ = "products"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4,)

    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    price = Column(
        Numeric(10, 2),
        nullable=False,
    )

    stock_quantity = Column(
        Integer,
        nullable=False,
        default=0,
    )
    
    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    combo_items = relationship(
        "ComboItem",
        foreign_keys="ComboItem.combo_product_id",
        back_populates="combo"
    )

    __table_args__ = (
        CheckConstraint(
            "stock_quantity >= 0",
            name="ck_product_stock_non_negative",
        ),
        CheckConstraint(
            "price > 0",
            name="ck_product_price_positive",
        ),
    )