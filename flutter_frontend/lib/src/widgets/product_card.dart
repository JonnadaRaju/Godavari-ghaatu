import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: ProductArtwork(product: product),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(label: product.categoryLabel),
                  _Tag(label: product.isVeg ? 'Veg' : 'Non-veg'),
                  if (product.isBestseller) const _Tag(label: 'Bestseller'),
                  if (product.isNewArrival) const _Tag(label: 'New'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B5C4E)),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rs ${product.price.toStringAsFixed(0)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.isInStock ? '${product.stockQuantity} in stock' : 'Out of stock',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: product.isInStock ? const Color(0xFF166534) : theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onAddToCart != null)
                    FilledButton.tonalIcon(
                      onPressed: product.isInStock ? onAddToCart : null,
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('Add'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductArtwork extends StatelessWidget {
  const ProductArtwork({super.key, required this.product, this.radius = 22});

  final Product product;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = _backgroundForCategory(product.category);
    final icon = _iconForCategory(product.category);

    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: color),
            Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(icon, color),
            ),
          ],
        ),
      );
    }

    return _fallback(icon, color);
  }

  Widget _fallback(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.92), color.withOpacity(0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 56, color: Colors.white),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

Color _backgroundForCategory(String category) {
  switch (category) {
    case 'pickle':
      return const Color(0xFFEA580C);
    case 'spice':
      return const Color(0xFFDC2626);
    case 'laddu':
      return const Color(0xFFD97706);
    case 'combo':
      return const Color(0xFF15803D);
    default:
      return const Color(0xFF6B7280);
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'pickle':
      return Icons.rice_bowl_rounded;
    case 'spice':
      return Icons.local_fire_department_rounded;
    case 'laddu':
      return Icons.cookie_rounded;
    case 'combo':
      return Icons.card_giftcard_rounded;
    default:
      return Icons.inventory_2_rounded;
  }
}
