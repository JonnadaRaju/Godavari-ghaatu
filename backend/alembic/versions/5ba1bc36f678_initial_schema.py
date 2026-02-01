"""initial schema

Revision ID: 5ba1bc36f678
Revises:
Create Date: 2026-02-01 21:26:44.949711
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "5ba1bc36f678"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    # -------------------------
    # Core tables
    # -------------------------
    op.create_table(
        "products",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("price", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        op.f("ix_users_email"),
        "users",
        ["email"],
        unique=True,
    )

    op.create_table(
        "carts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "orders",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # -------------------------
    # Bridge tables
    # -------------------------
    op.create_table(
        "cart_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("cart_id", sa.Integer(), nullable=False),
        sa.Column("product_id", sa.Integer(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["cart_id"], ["carts.id"]),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "order_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("order_id", sa.Integer(), nullable=False),
        sa.Column("product_id", sa.Integer(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("price", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"]),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "combo_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("combo_product_id", sa.Integer(), nullable=False),
        sa.Column("product_id", sa.Integer(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["combo_product_id"], ["products.id"]),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # -------------------------
    # CHECK constraints (quantity > 0)
    # -------------------------
    op.create_check_constraint(
        "ck_cart_items_quantity_positive",
        "cart_items",
        "quantity > 0",
    )

    op.create_check_constraint(
        "ck_order_items_quantity_positive",
        "order_items",
        "quantity > 0",
    )

    op.create_check_constraint(
        "ck_combo_items_quantity_positive",
        "combo_items",
        "quantity > 0",
    )

    # -------------------------
    # UNIQUE constraints (business invariants)
    # -------------------------
    op.create_unique_constraint(
        "uq_carts_user_id",
        "carts",
        ["user_id"],
    )

    op.create_unique_constraint(
        "uq_cart_items_cart_product",
        "cart_items",
        ["cart_id", "product_id"],
    )

    op.create_unique_constraint(
        "uq_order_items_order_product",
        "order_items",
        ["order_id", "product_id"],
    )

    op.create_unique_constraint(
        "uq_combo_items_combo_product",
        "combo_items",
        ["combo_product_id", "product_id"],
    )


def downgrade() -> None:
    """Downgrade schema."""

    # -------------------------
    # Drop UNIQUE constraints
    # -------------------------
    op.drop_constraint(
        "uq_combo_items_combo_product",
        "combo_items",
        type_="unique",
    )

    op.drop_constraint(
        "uq_order_items_order_product",
        "order_items",
        type_="unique",
    )

    op.drop_constraint(
        "uq_cart_items_cart_product",
        "cart_items",
        type_="unique",
    )

    op.drop_constraint(
        "uq_carts_user_id",
        "carts",
        type_="unique",
    )

    # -------------------------
    # Drop CHECK constraints
    # -------------------------
    op.drop_constraint(
        "ck_combo_items_quantity_positive",
        "combo_items",
        type_="check",
    )

    op.drop_constraint(
        "ck_order_items_quantity_positive",
        "order_items",
        type_="check",
    )

    op.drop_constraint(
        "ck_cart_items_quantity_positive",
        "cart_items",
        type_="check",
    )

    # -------------------------
    # Drop tables (reverse order)
    # -------------------------
    op.drop_table("combo_items")
    op.drop_table("order_items")
    op.drop_table("cart_items")
    op.drop_table("orders")
    op.drop_table("carts")

    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.drop_table("users")
    op.drop_table("products")
