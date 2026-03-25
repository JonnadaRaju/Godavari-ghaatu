import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/shop_controller.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onCategorySelected,
    required this.onProductSelected,
  });

  final ValueChanged<String> onCategorySelected;
  final ValueChanged<Product> onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        return RefreshIndicator(
          onRefresh: shop.loadProducts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Homemade flavors from the Godavari kitchen',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Browse pickles, podis, laddus, and combo packs backed by the existing FastAPI store.',
                      style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFFFFF2E8)),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF9A3412),
                          ),
                          onPressed: () => onCategorySelected('pickle'),
                          child: const Text('Shop Pickles'),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.18),
                          ),
                          onPressed: () => onCategorySelected('combo'),
                          child: const Text('Explore Combos'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                children: [
                  _CategoryTileHost(
                    label: 'Pickles',
                    color: const Color(0xFFF97316),
                    icon: Icons.rice_bowl_rounded,
                    onTap: () => onCategorySelected('pickle'),
                  ),
                  _CategoryTileHost(
                    label: 'Spices',
                    color: const Color(0xFFDC2626),
                    icon: Icons.local_fire_department_rounded,
                    onTap: () => onCategorySelected('spice'),
                  ),
                  _CategoryTileHost(
                    label: 'Laddus',
                    color: const Color(0xFFD97706),
                    icon: Icons.cookie_rounded,
                    onTap: () => onCategorySelected('laddu'),
                  ),
                  _CategoryTileHost(
                    label: 'Combos',
                    color: const Color(0xFF15803D),
                    icon: Icons.card_giftcard_rounded,
                    onTap: () => onCategorySelected('combo'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Featured picks',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onCategorySelected('all'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (shop.isProductsLoading && shop.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (shop.featuredProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No products available yet.'),
                )
              else
                ...shop.featuredProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ProductCard(
                      product: product,
                      onTap: () => onProductSelected(product),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTileHost extends StatelessWidget {
  const _CategoryTileHost({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
