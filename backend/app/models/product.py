from sqlalchemy import Column, Integer, String, Numeric, Boolean, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid

from app.core.database import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    name = Column(String, nullable=False)

    price = Column(
        Numeric(10, 2),
        nullable=False,
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    stock_quantity = Column(
        Integer,
        nullable=False,
        default=0,
    )

    combo_items = relationship(
        "ComboItem",
        back_populates="combo_product",
    )

    __table_args__ = (
        CheckConstraint(
            "stock_quantity >= 0",
            name="ck_product_stock_non_negative",
        ),
    )
