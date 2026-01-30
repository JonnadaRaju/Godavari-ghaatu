from sqlalchemy import Column, Integer, String, Numeric, Boolean
from sqlalchemy.orm import relationship

from app.core.database import Base

class Product(Base):
    __tablename__ = "products"
    
    id = Column(Integer, Primary_key=True)
    name = Column(String, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    is_active = Column(Boolean, default=True)