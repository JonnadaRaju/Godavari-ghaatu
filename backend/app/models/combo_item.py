from sqlalchemy import Column, Integer, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class ComboItem(Base):
    
    __tablename__ = "combo_items"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    combo_product_id = Column(
        UUID(as_uuid=True),
        ForeignKey("products.id", ondelete="CASCADE"),
        nullable=False
    )
    product_id = Column(
        UUID(as_uuid=True),
        ForeignKey("products.id", ondelete="CASCADE"),
        nullable=False
    )
    
    quantity = Column(Integer, nullable=False)
    
    combo = relationship(
        "Product",
        foreign_keys=[combo_product_id],
        back_populates="combo_items"
    )
    product = relationship(
        "Product",
        foreign_keys=[product_id]
    )
    
    __table_args__ = (
        CheckConstraint(
            "quantity > 0",
            name="ck_combo_item_quantity_positive"
        ),
    )