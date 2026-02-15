from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import auth, users, products, cart, orders, payments
from app.routers import product_variants
from app.routers import wishlist
from app.routers import reviews
from app.routers import combos

app = FastAPI(
    title=settings.APP_NAME,
    description="E-commerce backend API with cart, orders, and payments",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(products.router, prefix="/api/v1")
app.include_router(product_variants.router, prefix="/api/v1")
app.include_router(reviews.router, prefix="/api/v1")
app.include_router(combos.router, prefix="/api/v1")
app.include_router(cart.router, prefix="/api/v1")
app.include_router(orders.router, prefix="/api/v1")
app.include_router(payments.router, prefix="/api/v1")
app.include_router(wishlist.router, prefix="/api/v1")


@app.get("/")
def root():
    return {
        "message": f"{settings.APP_NAME} API is running",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}