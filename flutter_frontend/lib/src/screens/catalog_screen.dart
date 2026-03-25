import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/shop_controller.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onProductSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<Product> onProductSelected;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late String _selectedCategory;
  String _searchQuery = '';
  bool _vegOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _selectedCategory = widget.selectedCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        final filteredProducts = shop.products.where((product) {
          final matchesCategory = _selectedCategory == 'all' || product.category == _selectedCategory;
          final matchesVeg = !_vegOnly || product.isVeg;
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              product.description.toLowerCase().contains(query);
          return matchesCategory && matchesVeg && matchesSearch;
        }).toList();

        return RefreshIndicator(
          onRefresh: shop.loadProducts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search pickles, spices, laddus...',
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final category in const ['all', 'pickle', 'spice', 'laddu', 'combo'])
                    ChoiceChip(
                      label: Text(_categoryLabel(category)),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        widget.onCategoryChanged(category);
                      },
                    ),
                  FilterChip(
                    label: const Text('Veg only'),
                    selected: _vegOnly,
                    onSelected: (value) {
                      setState(() {
                        _vegOnly = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${filteredProducts.length} products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (shop.isProductsLoading && shop.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text('No products matched the current filters.'),
                )
              else
                ...filteredProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ProductCard(
                      product: product,
                      onTap: () => widget.onProductSelected(product),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'pickle':
        return 'Pickles';
      case 'spice':
        return 'Spices';
      case 'laddu':
        return 'Laddus';
      case 'combo':
        return 'Combos';
      default:
        return 'All';
    }
  }
}
