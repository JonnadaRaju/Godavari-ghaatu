from alembic import op
import sqlalchemy as sa

revision: str = 'd5e3c9f2a1b6'
down_revision = 'c4d2b8f1e9a7'      
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create wishlists table
    op.create_table(
        'wishlists',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('product_id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'product_id', name='uq_wishlist_user_product'),
    )

    # Note: PACKED status is handled in application code (order_state.py)
    # No DB schema change needed — status column is a plain String


def downgrade() -> None:
    op.drop_table('wishlists')