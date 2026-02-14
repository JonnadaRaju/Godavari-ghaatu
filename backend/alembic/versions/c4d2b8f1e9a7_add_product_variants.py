"""Add product_variants table and variant columns to cart_items and order_items

Revision ID: c4d2b8f1e9a7
Revises: (replace_with_your_last_revision_id)
Create Date: 2026-02-13

"""
from alembic import op
import sqlalchemy as sa

# ← IMPORTANT: replace the value below with your actual last revision ID
# Run `alembic history` to find it
revision: str = 'c4d2b8f1e9a7'
down_revision = 'your_last_revision_id_here'
branch_labels = None
depends_on = None


def upgrade() -> None:

    # 1. Create product_variants table
    op.create_table(
        'product_variants',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('product_id', sa.UUID(), nullable=False),
        sa.Column('label', sa.String(length=100), nullable=False),
        sa.Column('price', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('stock_quantity', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.CheckConstraint('price > 0', name='ck_variant_price_positive'),
        sa.CheckConstraint('stock_quantity >= 0', name='ck_variant_stock_non_negative'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    # 2. Add variant_id to cart_items (nullable — existing rows have no variant)
    op.add_column('cart_items', sa.Column('variant_id', sa.UUID(), nullable=True))
    op.create_foreign_key(
        'fk_cart_items_variant_id',
        'cart_items', 'product_variants',
        ['variant_id'], ['id'],
        ondelete='SET NULL'
    )

    # 3. Drop old unique constraint on cart_items (cart_id, product_id)
    #    and replace with (cart_id, product_id, variant_id)
    op.drop_constraint('uq_cart_product', 'cart_items', type_='unique')
    op.create_unique_constraint(
        'uq_cart_product_variant',
        'cart_items',
        ['cart_id', 'product_id', 'variant_id']
    )

    # 4. Add variant_id and variant_label to order_items
    op.add_column('order_items', sa.Column('variant_id', sa.UUID(), nullable=True))
    op.add_column('order_items', sa.Column('variant_label', sa.String(length=100), nullable=True))
    op.create_foreign_key(
        'fk_order_items_variant_id',
        'order_items', 'product_variants',
        ['variant_id'], ['id'],
        ondelete='SET NULL'
    )


def downgrade() -> None:

    # Reverse order_items changes
    op.drop_constraint('fk_order_items_variant_id', 'order_items', type_='foreignkey')
    op.drop_column('order_items', 'variant_label')
    op.drop_column('order_items', 'variant_id')

    # Reverse cart_items changes
    op.drop_constraint('uq_cart_product_variant', 'cart_items', type_='unique')
    op.create_unique_constraint('uq_cart_product', 'cart_items', ['cart_id', 'product_id'])
    op.drop_constraint('fk_cart_items_variant_id', 'cart_items', type_='foreignkey')
    op.drop_column('cart_items', 'variant_id')

    # Drop product_variants table
    op.drop_table('product_variants')