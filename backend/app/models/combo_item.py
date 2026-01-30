from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class ComboItem(Base):
    __tablename__ = "combo_items"
    
    id = Column(Integer, primary_key=True)
    combo_product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    
    combo = relationship("Product",foreign_keys=[combo_product_id],)
    product = relationship("Product",foreign_keys=[product_id],)