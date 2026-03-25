import pytest
import sys
import os
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import uuid

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app
from app.core.database import Base, get_db
from app.core.security import hash_password
from app.models.user import User
from app.models.product import Product
from app.models.cart import Cart, CartItem
from app.models.order import Order, OrderItem


SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="function")
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db):
    return TestClient(app)


@pytest.fixture
def test_user(db):
    user = User(
        id=uuid.uuid4(),
        email="test@example.com",
        hashed_password=hash_password("testpassword123"),
        full_name="Test User",
        phone="1234567890",
        role="customer",
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def admin_user(db):
    user = User(
        id=uuid.uuid4(),
        email="admin@example.com",
        hashed_password=hash_password("adminpass123"),
        full_name="Admin User",
        phone="9876543210",
        role="admin",
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def auth_token(client, test_user):
    response = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "testpassword123"
    })
    return response.json()["access_token"]


@pytest.fixture
def admin_token(client, admin_user):
    response = client.post("/api/v1/auth/login", json={
        "email": "admin@example.com",
        "password": "adminpass123"
    })
    return response.json()["access_token"]


@pytest.fixture
def test_product(db, admin_user):
    product = Product(
        id=uuid.uuid4(),
        name="Test Pickle",
        description="Delicious test pickle",
        price=250.00,
        stock_quantity=100,
        image_url="https://example.com/pickle.jpg",
        category="pickle",
        is_veg=True,
        is_bestseller=False,
        is_new_arrival=True,
        is_active=True
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@pytest.fixture
def combo_product(db, admin_user):
    product = Product(
        id=uuid.uuid4(),
        name="Family Combo",
        description="Curated combo pack",
        price=499.00,
        stock_quantity=25,
        image_url="https://example.com/combo.jpg",
        category="combo",
        is_veg=True,
        is_bestseller=True,
        is_new_arrival=False,
        is_active=True
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


class TestRootEndpoint:
    def test_root_endpoint(self, client):
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "version" in data

    def test_health_check(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "healthy"}


class TestAuth:
    def test_register_new_user(self, client):
        response = client.post("/api/v1/auth/register", json={
            "email": "newuser@example.com",
            "password": "newpass123",
            "full_name": "New User",
            "phone": "9876543211"
        })
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert data["full_name"] == "New User"
        assert "hashed_password" not in data

    def test_register_duplicate_email(self, client, test_user):
        response = client.post("/api/v1/auth/register", json={
            "email": "test@example.com",
            "password": "newpass123",
            "full_name": "Duplicate User",
            "phone": "9876543211"
        })
        assert response.status_code == 409

    def test_login_success(self, client, test_user):
        response = client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "testpassword123"
        })
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    def test_login_wrong_password(self, client, test_user):
        response = client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "wrongpassword"
        })
        assert response.status_code == 401

    def test_login_nonexistent_user(self, client):
        response = client.post("/api/v1/auth/login", json={
            "email": "nonexistent@example.com",
            "password": "somepass123"
        })
        assert response.status_code == 401


class TestProducts:
    def test_list_products_empty(self, client):
        response = client.get("/api/v1/products")
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    def test_list_products_with_data(self, client, test_product):
        response = client.get("/api/v1/products")
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1

    def test_list_products_by_category(self, client, test_product):
        response = client.get("/api/v1/products?category=pickle")
        assert response.status_code == 200
        data = response.json()
        assert all(p["category"] == "pickle" for p in data)

    def test_get_product_by_id(self, client, test_product):
        response = client.get(f"/api/v1/products/{test_product.id}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test Pickle"

    def test_get_product_not_found(self, client):
        fake_id = uuid.uuid4()
        response = client.get(f"/api/v1/products/{fake_id}")
        assert response.status_code == 404

    def test_create_product_as_admin(self, client, admin_token):
        response = client.post("/api/v1/products", 
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "name": "New Product",
                "description": "Test description",
                "price": 300.00,
                "stock_quantity": 50,
                "image_url": "https://example.com/image.jpg",
                "category": "spice",
                "is_veg": True,
                "is_bestseller": True,
                "is_new_arrival": False,
                "is_active": True
            })
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "New Product"

    def test_create_product_without_auth(self, client):
        response = client.post("/api/v1/products", json={
            "name": "New Product",
            "description": "Test description",
            "price": 300.00,
            "stock_quantity": 50,
            "image_url": "https://example.com/image.jpg",
            "category": "spice",
            "is_veg": True,
            "is_bestseller": True,
            "is_new_arrival": False,
            "is_active": True
        })
        assert response.status_code == 401

    def test_update_product_as_admin(self, client, admin_token, test_product):
        response = client.put(f"/api/v1/products/{test_product.id}",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "name": "Updated Pickle",
                "price": 299.00
            })
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Pickle"
        assert data["price"] == 299.00

    def test_delete_product_as_admin(self, client, admin_token, test_product):
        response = client.delete(f"/api/v1/products/{test_product.id}",
            headers={"Authorization": f"Bearer {admin_token}"})
        assert response.status_code == 204
        
        response = client.get(f"/api/v1/products/{test_product.id}")
        assert response.status_code == 200
        assert response.json()["is_active"] == False


class TestCart:
    def test_get_empty_cart(self, client, auth_token):
        response = client.get("/api/v1/cart", 
            headers={"Authorization": f"Bearer {auth_token}"})
        assert response.status_code == 200
        data = response.json()
        assert data["items"] == []

    def test_add_item_to_cart(self, client, auth_token, test_product):
        response = client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        assert response.status_code == 201
        data = response.json()
        assert len(data["items"]) == 1
        assert data["items"][0]["quantity"] == 2

    def test_update_cart_item(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        cart_response = client.get("/api/v1/cart",
            headers={"Authorization": f"Bearer {auth_token}"})
        item_id = cart_response.json()["items"][0]["id"]
        
        response = client.put(f"/api/v1/cart/items/{item_id}",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"quantity": 5})
        
        assert response.status_code == 200
        assert response.json()["items"][0]["quantity"] == 5

    def test_delete_cart_item(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        cart_response = client.get("/api/v1/cart",
            headers={"Authorization": f"Bearer {auth_token}"})
        item_id = cart_response.json()["items"][0]["id"]
        
        response = client.delete(f"/api/v1/cart/items/{item_id}",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 200
        assert len(response.json()["items"]) == 0

    def test_clear_cart(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        response = client.delete("/api/v1/cart",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 204


class TestOrders:
    def test_create_order_from_cart(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 201
        data = response.json()
        assert data["status"] == "PENDING"
        assert len(data["items"]) == 1

    def test_create_order_empty_cart(self, client, auth_token):
        response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        assert response.status_code == 409

    def test_list_user_orders(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        response = client.get("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1

    def test_get_order_by_id(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]
        
        response = client.get(f"/api/v1/orders/{order_id}",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 200
        assert response.json()["id"] == order_id

    def test_cancel_order(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]
        
        response = client.patch(f"/api/v1/orders/{order_id}/cancel",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 200
        assert response.json()["status"] == "CANCELLED"

    def test_admin_pack_order(self, client, auth_token, admin_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]
        
        client.post(f"/api/v1/payments/verify/{order_id}",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        response = client.patch(f"/api/v1/orders/{order_id}/pack",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        assert response.status_code == 200
        assert response.json()["status"] == "PACKED"

    def test_admin_ship_order(self, client, auth_token, admin_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]
        
        client.post(f"/api/v1/payments/verify/{order_id}",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        client.patch(f"/api/v1/orders/{order_id}/pack",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        response = client.patch(f"/api/v1/orders/{order_id}/ship",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        assert response.status_code == 200
        assert response.json()["status"] == "SHIPPED"

    def test_admin_deliver_order(self, client, auth_token, admin_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })
        
        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]
        
        client.post(f"/api/v1/payments/verify/{order_id}",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        client.patch(f"/api/v1/orders/{order_id}/pack",
            headers={"Authorization": f"Bearer {admin_token}"})
        client.patch(f"/api/v1/orders/{order_id}/ship",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        response = client.patch(f"/api/v1/orders/{order_id}/deliver",
            headers={"Authorization": f"Bearer {admin_token}"})
        
        assert response.status_code == 200
        assert response.json()["status"] == "DELIVERED"


class TestProductVariants:
    def test_list_product_variants_empty(self, client, test_product):
        response = client.get(f"/api/v1/products/{test_product.id}/variants")

        assert response.status_code == 200
        assert response.json() == []

    def test_create_product_variant_as_admin(self, client, admin_token, test_product):
        response = client.post(
            f"/api/v1/products/{test_product.id}/variants",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "label": "500g",
                "price": 320.00,
                "stock_quantity": 40,
                "is_active": True
            }
        )

        assert response.status_code == 201
        data = response.json()
        assert data["label"] == "500g"
        assert data["price"] == 320.0

    def test_update_product_variant_as_admin(self, client, admin_token, test_product):
        create_response = client.post(
            f"/api/v1/products/{test_product.id}/variants",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "label": "250g",
                "price": 180.00,
                "stock_quantity": 25,
                "is_active": True
            }
        )
        variant_id = create_response.json()["id"]

        response = client.put(
            f"/api/v1/products/{test_product.id}/variants/{variant_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "label": "1kg",
                "price": 600.00,
                "stock_quantity": 12
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["label"] == "1kg"
        assert data["price"] == 600.0
        assert data["stock_quantity"] == 12

    def test_delete_product_variant_as_admin(self, client, admin_token, test_product):
        create_response = client.post(
            f"/api/v1/products/{test_product.id}/variants",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "label": "Pack of 6",
                "price": 250.00,
                "stock_quantity": 15,
                "is_active": True
            }
        )
        variant_id = create_response.json()["id"]

        response = client.delete(
            f"/api/v1/products/{test_product.id}/variants/{variant_id}",
            headers={"Authorization": f"Bearer {admin_token}"}
        )

        assert response.status_code == 204

        list_response = client.get(f"/api/v1/products/{test_product.id}/variants")
        assert list_response.status_code == 200
        assert list_response.json() == []


class TestCombos:
    def test_list_combo_items_empty(self, client, combo_product):
        response = client.get(f"/api/v1/products/{combo_product.id}/combo-items")

        assert response.status_code == 200
        assert response.json() == []

    def test_add_combo_item_as_admin(self, client, admin_token, combo_product, test_product):
        response = client.post(
            f"/api/v1/products/{combo_product.id}/combo-items",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "component_product_id": str(test_product.id),
                "quantity": 2
            }
        )

        assert response.status_code == 201
        data = response.json()
        assert data["component_product_id"] == str(test_product.id)
        assert data["component_name"] == "Test Pickle"
        assert data["quantity"] == 2

    def test_update_combo_item_as_admin(self, client, admin_token, combo_product, test_product):
        create_response = client.post(
            f"/api/v1/products/{combo_product.id}/combo-items",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "component_product_id": str(test_product.id),
                "quantity": 1
            }
        )
        combo_item_id = create_response.json()["id"]

        response = client.put(
            f"/api/v1/products/{combo_product.id}/combo-items/{combo_item_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={"quantity": 3}
        )

        assert response.status_code == 200
        assert response.json()["quantity"] == 3

    def test_remove_combo_item_as_admin(self, client, admin_token, combo_product, test_product):
        create_response = client.post(
            f"/api/v1/products/{combo_product.id}/combo-items",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "component_product_id": str(test_product.id),
                "quantity": 1
            }
        )
        combo_item_id = create_response.json()["id"]

        response = client.delete(
            f"/api/v1/products/{combo_product.id}/combo-items/{combo_item_id}",
            headers={"Authorization": f"Bearer {admin_token}"}
        )

        assert response.status_code == 204

        list_response = client.get(f"/api/v1/products/{combo_product.id}/combo-items")
        assert list_response.status_code == 200
        assert list_response.json() == []


class TestPayments:
    def test_get_upi_payment_info(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 2
            })

        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]

        response = client.get(
            f"/api/v1/payments/upi/{order_id}",
            headers={"Authorization": f"Bearer {auth_token}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["order_id"] == order_id[:8].upper()
        assert data["qr_code"].startswith("data:image/png;base64,")

    def test_upload_payment_screenshot(self, client, auth_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 1
            })

        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]

        response = client.post(
            f"/api/v1/payments/upi/{order_id}/upload-screenshot",
            headers={"Authorization": f"Bearer {auth_token}"},
            files={"file": ("payment.png", b"fake-image-content", "image/png")}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["order_id"] == order_id
        assert data["filename"] == "payment.png"

    def test_verify_payment_as_admin(self, client, auth_token, admin_token, test_product):
        client.post("/api/v1/cart/items",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "product_id": str(test_product.id),
                "quantity": 1
            })

        order_response = client.post("/api/v1/orders",
            headers={"Authorization": f"Bearer {auth_token}"})
        order_id = order_response.json()["id"]

        response = client.post(
            f"/api/v1/payments/verify/{order_id}",
            headers={"Authorization": f"Bearer {admin_token}"}
        )

        assert response.status_code == 200
        assert response.json()["status"] == "PAID"


class TestWishlist:
    def test_add_to_wishlist(self, client, auth_token, test_product):
        response = client.post("/api/v1/wishlist",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"product_id": str(test_product.id)})
        assert response.status_code == 201

    def test_get_wishlist(self, client, auth_token, test_product):
        client.post("/api/v1/wishlist",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"product_id": str(test_product.id)})
        
        response = client.get("/api/v1/wishlist",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1

    def test_remove_from_wishlist(self, client, auth_token, test_product):
        client.post("/api/v1/wishlist",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"product_id": str(test_product.id)})
        
        response = client.delete(f"/api/v1/wishlist/{test_product.id}",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 204


class TestReviews:
    def test_create_review(self, client, auth_token, test_product):
        response = client.post(f"/api/v1/products/{test_product.id}/reviews",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "rating": 5,
                "comment": "Great product!"
            })
        assert response.status_code == 201

    def test_get_product_reviews(self, client, auth_token, test_product):
        client.post(f"/api/v1/products/{test_product.id}/reviews",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "rating": 4,
                "comment": "Good product"
            })
        
        response = client.get(f"/api/v1/products/{test_product.id}/reviews")
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1

    def test_get_product_review_summary(self, client, auth_token, test_product):
        client.post(f"/api/v1/products/{test_product.id}/reviews",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "rating": 5,
                "comment": "Excellent product"
            })

        response = client.get(f"/api/v1/products/{test_product.id}/reviews/summary")

        assert response.status_code == 200
        assert response.json() == {
            "average_rating": 5.0,
            "review_count": 1
        }

    def test_update_review(self, client, auth_token, test_product):
        create_response = client.post(f"/api/v1/products/{test_product.id}/reviews",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "rating": 4,
                "comment": "Good product"
            })
        review_id = create_response.json()["id"]

        response = client.put(
            f"/api/v1/products/{test_product.id}/reviews/{review_id}",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "rating": 5,
                "comment": "Updated review"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["rating"] == 5
        assert data["comment"] == "Updated review"

    def test_delete_review(self, client, auth_token, test_product):
        create_response = client.post(f"/api/v1/products/{test_product.id}/reviews",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "rating": 3,
                "comment": "Average product"
            })
        review_id = create_response.json()["id"]

        response = client.delete(
            f"/api/v1/products/{test_product.id}/reviews/{review_id}",
            headers={"Authorization": f"Bearer {auth_token}"}
        )

        assert response.status_code == 204

        list_response = client.get(f"/api/v1/products/{test_product.id}/reviews")
        assert list_response.status_code == 200
        assert list_response.json() == []


class TestUsers:
    def test_get_current_user(self, client, auth_token):
        response = client.get("/api/v1/users/me",
            headers={"Authorization": f"Bearer {auth_token}"})
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "test@example.com"

    def test_update_profile(self, client, auth_token):
        response = client.put("/api/v1/users/me",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "full_name": "Updated Name",
                "phone": "9999999999"
            })
        
        assert response.status_code == 200
        assert response.json()["full_name"] == "Updated Name"

    def test_change_password(self, client, auth_token):
        response = client.post("/api/v1/users/me/change-password",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "current_password": "testpassword123",
                "new_password": "newpassword456"
            })

        assert response.status_code == 200
        assert response.json()["message"] == "Password changed successfully"

        login_response = client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "newpassword456"
        })
        assert login_response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
