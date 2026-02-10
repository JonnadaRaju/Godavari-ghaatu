from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.core.config import settings

DATABASE_URL = "postgresql://raju:6014@localhost:5432/rajudb"


engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True, echo=settings.DEBUG,)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class Base(DeclarativeBase):
    pass

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()