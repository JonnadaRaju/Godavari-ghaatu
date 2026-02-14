from sqlalchemy import Column, String, Integer, Numeric, Boolean, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class ProductVariant(Base):

    __tablename__ = "product_variants"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    product_id = Column(
        UUID(as_uuid=True),
        ForeignKey("products.id", ondelete="CASCADE"),
        nullable=False
    )

    label = Column(
        String(100),
        nullable=False,
        comment="e.g. '250g', '500g', '1kg', 'Pack of 6', 'Pack of 12'"
    )

    price = Column(
        Numeric(10, 2),
        nullable=False,
        comment="Price for this specific variant"
    )

    stock_quantity = Column(
        Integer,
        nullable=False,
        default=0,
        comment="Stock for this specific variant"
    )

    is_active = Column(Boolean, nullable=False, default=True)

    # Relationship back to product
    product = relationship("Product", back_populates="variants")

    __table_args__ = (
        CheckConstraint("price > 0", name="ck_variant_price_positive"),
        CheckConstraint("stock_quantity >= 0", name="ck_variant_stock_non_negative"),
    )

    def __repr__(self):
        return f"<ProductVariant(product={self.product_id}, label={self.label}, price={self.price})>"
