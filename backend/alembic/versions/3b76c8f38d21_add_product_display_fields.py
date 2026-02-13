"""add product display fields

Revision ID: 3b76c8f38d21
Revises: 2a65b7e27c10
Create Date: 2026-02-13 14:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3b76c8f38d21'
down_revision: Union[str, None] = '2a65b7e27c10'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add display fields to products table."""
    
    # Add image_url column
    op.add_column('products', 
        sa.Column('image_url', sa.String(length=500), nullable=True, comment='Product image URL')
    )
    
    # Add category column with default value
    op.add_column('products',
        sa.Column('category', sa.String(length=50), nullable=False, server_default='pickle', comment='Product category: pickle, spice, laddu, combo')
    )
    
    # Add is_veg column with default True
    op.add_column('products',
        sa.Column('is_veg', sa.Boolean(), nullable=False, server_default='true', comment='True for vegetarian products')
    )
    
    # Add is_bestseller column with default False
    op.add_column('products',
        sa.Column('is_bestseller', sa.Boolean(), nullable=False, server_default='false', comment='Mark as bestseller for homepage featured section')
    )
    
    # Add is_new_arrival column with default False
    op.add_column('products',
        sa.Column('is_new_arrival', sa.Boolean(), nullable=False, server_default='false', comment='Mark as new arrival for marketing')
    )
    
    # Create index for category (for filtering)
    op.create_index('ix_products_category', 'products', ['category'])
    
    # Create index for is_veg (for filtering)
    op.create_index('ix_products_is_veg', 'products', ['is_veg'])
    
    # Create index for is_bestseller (for homepage queries)
    op.create_index('ix_products_is_bestseller', 'products', ['is_bestseller'])
    
    # Create index for is_new_arrival (for marketing queries)
    op.create_index('ix_products_is_new_arrival', 'products', ['is_new_arrival'])
    
    # Create composite index for common queries
    op.create_index('ix_products_category_is_veg', 'products', ['category', 'is_veg'])


def downgrade() -> None:
    """Remove display fields from products table."""
    
    # Drop indexes first
    op.drop_index('ix_products_category_is_veg', table_name='products')
    op.drop_index('ix_products_is_new_arrival', table_name='products')
    op.drop_index('ix_products_is_bestseller', table_name='products')
    op.drop_index('ix_products_is_veg', table_name='products')
    op.drop_index('ix_products_category', table_name='products')
    
    # Drop columns
    op.drop_column('products', 'is_new_arrival')
    op.drop_column('products', 'is_bestseller')
    op.drop_column('products', 'is_veg')
    op.drop_column('products', 'category')
    op.drop_column('products', 'image_url')