import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/combo_item.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../state/shop_controller.dart';
import '../widgets/admin_art.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onRequireAuth,
  });

  final Product product;
  final Future<void> Function() onRequireAuth;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoadingVariants = true;
  bool _isLoadingComboItems = false;
  List<ProductVariant> _variants = <ProductVariant>[];
  List<ComboItem> _comboItems = <ComboItem>[];
  ProductVariant? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _primeScreen();
  }

  Future<void> _primeScreen() async {
    await _loadVariants();
    if (widget.product.isCombo) {
      await _loadComboItems();
    }
  }

  Future<void> _loadVariants() async {
    final variants = await context.read<ShopController>().loadVariants(widget.product.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _variants = variants;
      _selectedVariant = variants.isNotEmpty ? variants.first : null;
      _isLoadingVariants = false;
    });
  }

  Future<void> _loadComboItems() async {
    setState(() {
      _isLoadingComboItems = true;
    });

    final comboItems = await context.read<ShopController>().loadComboItems(widget.product.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _comboItems = comboItems;
      _isLoadingComboItems = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopController>();
    final unitPrice = _selectedVariant?.price ?? widget.product.price;
    final stock = _selectedVariant?.stockQuantity ?? widget.product.stockQuantity;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          ProductArtwork(product: widget.product, radius: 28),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: widget.product.categoryLabel),
              _MetaChip(label: widget.product.isVeg ? 'Veg' : 'Non-veg'),
              if (widget.product.averageRating != null)
                _MetaChip(label: 'Rating ${widget.product.averageRating!.toStringAsFixed(1)}'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: const Color(0xFF5B5146)),
          ),
          if (widget.product.isCombo) ...[
            const SizedBox(height: 18),
            ComboBlueprintCard(
              title: 'What is inside this combo?',
              subtitle: 'Every combo is backed by the same bundle composition used in the admin product studio.',
              child: _isLoadingComboItems
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _comboItems.isEmpty
                      ? const Text('Combo items will appear here once the backend composition is available.')
                      : Column(
                          children: _comboItems
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.componentName,
                                              style: const TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.quantity} x Rs ${item.componentPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(color: Color(0xFF6B5C4E)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE7F5EA),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${item.quantity}x',
                                          style: const TextStyle(
                                            color: Color(0xFF166534),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
            ),
          ],
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs ${unitPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stock > 0 ? '$stock units available' : 'Currently out of stock',
                    style: TextStyle(
                      color: stock > 0 ? const Color(0xFF166534) : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_isLoadingVariants)
                    const Center(child: CircularProgressIndicator())
                  else if (_variants.isNotEmpty)
                    DropdownButtonFormField<ProductVariant>(
                      value: _selectedVariant,
                      decoration: const InputDecoration(labelText: 'Variant'),
                      items: _variants
                          .map(
                            (variant) => DropdownMenuItem<ProductVariant>(
                              value: variant,
                              child: Text('${variant.label} - Rs ${variant.price.toStringAsFixed(0)}'),
                            ),
                          )
                          .toList(),
                      onChanged: (variant) {
                        setState(() {
                          _selectedVariant = variant;
                        });
                      },
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity -= 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _quantity < stock
                            ? () {
                                setState(() {
                                  _quantity += 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: stock > 0 && !shop.isCartBusy ? _handleAddToCart : null,
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: Text(shop.isCartBusy ? 'Adding...' : 'Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToCart() async {
    final shop = context.read<ShopController>();
    if (!shop.isAuthenticated) {
      await widget.onRequireAuth();
      if (!mounted || !context.read<ShopController>().isAuthenticated) {
        return;
      }
    }

    final success = await context.read<ShopController>().addToCart(
          productId: widget.product.id,
          quantity: _quantity,
          variantId: _selectedVariant?.id,
        );

    if (!mounted) {
      return;
    }

    final message = success
        ? '${widget.product.name} added to cart'
        : context.read<ShopController>().errorMessage ?? 'Unable to add item to cart';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
