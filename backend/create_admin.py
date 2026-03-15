import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.core.security import hash_password, verify_password
from app.models.user import User
import uuid

def create_admin():
    db = SessionLocal()
    
    # Check if admin exists
    existing = db.query(User).filter(User.email == "admin@godavari.com").first()
    if existing:
        print(f"Admin user already exists: {existing.email}")
        print(f"Role: {existing.role}")
        
        # Test password
        test_pw = "admin123"
        if verify_password(test_pw, existing.hashed_password):
            print(f"Password 'admin123' is CORRECT")
        else:
            print(f"Password 'admin123' is INCORRECT")
            # Reset password
            existing.hashed_password = hash_password("admin123")
            db.commit()
            print("Password reset to 'admin123'")
        return
    
    # Create new admin
    admin = User(
        id=uuid.uuid4(),
        email="admin@godavari.com",
        hashed_password=hash_password("admin123"),
        full_name="Admin",
        phone="9876543210",
        role="admin",
        is_active=True
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    
    print(f"Admin created successfully!")
    print(f"Email: admin@godavari.com")
    print(f"Password: admin123")
    print(f"Role: admin")

if __name__ == "__main__":
    create_admin()
