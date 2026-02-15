
from alembic import op
import sqlalchemy as sa

revision: str = 'e6f4d0a3b2c8'
down_revision = 'd5e3c9f2a1b6'  
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'reviews',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('product_id', sa.UUID(), nullable=False),
        sa.Column('rating', sa.Integer(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.CheckConstraint('rating >= 1 AND rating <= 5', name='ck_review_rating_range'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'product_id', name='uq_review_user_product'),
    )

    op.add_column('orders', sa.Column('subtotal', sa.Numeric(precision=10, scale=2), nullable=True))
    op.add_column('orders', sa.Column('delivery_charge', sa.Numeric(precision=10, scale=2), nullable=True))
    op.add_column('orders', sa.Column('tax_amount', sa.Numeric(precision=10, scale=2), nullable=True))

    op.execute("""
        UPDATE orders
        SET subtotal = total_amount,
            delivery_charge = 0,
            tax_amount = 0
        WHERE subtotal IS NULL
    """)

    # 4. Make columns non-nullable now that they're filled
    op.alter_column('orders', 'subtotal', nullable=False)
    op.alter_column('orders', 'delivery_charge', nullable=False)
    op.alter_column('orders', 'tax_amount', nullable=False)


def downgrade() -> None:
    op.drop_column('orders', 'tax_amount')
    op.drop_column('orders', 'delivery_charge')
    op.drop_column('orders', 'subtotal')
    op.drop_table('reviews')