import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/combo_item.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../state/shop_controller.dart';
import '../widgets/admin_art.dart';
import '../widgets/product_card.dart';
import 'admin_product_form_screen.dart';

class AdminProductWorkspaceScreen extends StatefulWidget {
  const AdminProductWorkspaceScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  final String productId;
  final Product? initialProduct;

  @override
  State<AdminProductWorkspaceScreen> createState() => _AdminProductWorkspaceScreenState();
}

class _AdminProductWorkspaceScreenState extends State<AdminProductWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoadingVariants = true;
  bool _isLoadingComboItems = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeWorkspace();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _primeWorkspace() async {
    await _loadVariants(forceRefresh: true);
    await _loadComboItems(forceRefresh: true);
  }

  Future<void> _loadVariants({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingVariants = true;
    });

    await context.read<ShopController>().loadVariants(widget.productId, forceRefresh: forceRefresh);
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingVariants = false;
    });
  }

  Future<void> _loadComboItems({bool forceRefresh = false}) async {
    final shop = context.read<ShopController>();
    final product = shop.findProduct(widget.productId) ?? widget.initialProduct;
    if (product == null || !product.isCombo) {
      setState(() {
        _isLoadingComboItems = false;
      });
      return;
    }

    setState(() {
      _isLoadingComboItems = true;
    });

    await shop.loadComboItems(widget.productId, forceRefresh: forceRefresh);
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingComboItems = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        final product = shop.findProduct(widget.productId) ?? widget.initialProduct;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Studio')),
            body: const Center(
              child: Text('This product is no longer available in the admin catalog.'),
            ),
          );
        }

        final variants = shop.variantsFor(product.id);
        final comboItems = shop.comboItemsFor(product.id);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Product Studio'),
            actions: [
              IconButton(
                onPressed: () {
                  _openProductEditor(product);
                },
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit product',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Variants'),
                Tab(text: 'Bundle'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                product: product,
                variants: variants,
                comboItems: comboItems,
                isAdminWorking: shop.isAdminWorking,
                onRefresh: () async {
                  await _primeWorkspace();
                  await shop.refreshAdminData();
                },
                onEdit: () => _openProductEditor(product),
                onArchiveToggle: () => _toggleArchive(product),
              ),
              _VariantsTab(
                product: product,
                variants: variants,
                isLoading: _isLoadingVariants,
                isBusy: shop.isAdminWorking,
                onRefresh: () => _loadVariants(forceRefresh: true),
                onAdd: () => _showVariantEditor(product: product),
                onEdit: (variant) => _showVariantEditor(product: product, variant: variant),
                onArchive: (variant) => _archiveVariant(product, variant),
              ),
              _BundleTab(
                product: product,
                items: comboItems,
                availableProducts: shop.adminProducts
                    .where((item) => item.id != product.id && item.isActive)
                    .toList(),
                isLoading: _isLoadingComboItems,
                isBusy: shop.isAdminWorking,
                onRefresh: () => _loadComboItems(forceRefresh: true),
                onConvertToCombo: () => _convertToCombo(product),
                onAddItem: () => _showComboItemEditor(product: product),
                onEditItem: (item) => _showComboItemEditor(product: product, existingItem: item),
                onRemoveItem: (item) => _removeComboItem(product, item),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openProductEditor(Product product) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminProductFormScreen(product: product),
      ),
    );
  }

  Future<void> _toggleArchive(Product product) async {
    final shop = context.read<ShopController>();
    final success = product.isActive
        ? await shop.archiveProduct(product.id)
        : await shop.restoreProduct(product.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (product.isActive ? '${product.name} archived' : '${product.name} restored')
              : shop.errorMessage ?? 'Unable to update product',
        ),
      ),
    );
  }

  Future<void> _convertToCombo(Product product) async {
    final shop = context.read<ShopController>();
    final success = await shop.updateProduct(
      product.id,
      <String, dynamic>{
        'category': 'combo',
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'stock_quantity': product.stockQuantity,
        'image_url': product.imageUrl,
        'is_veg': product.isVeg,
        'is_bestseller': product.isBestseller,
        'is_new_arrival': product.isNewArrival,
        'is_active': product.isActive,
      },
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Product converted to combo' : shop.errorMessage ?? 'Unable to convert product'),
      ),
    );

    if (success) {
      await _loadComboItems(forceRefresh: true);
    }
  }

  Future<void> _archiveVariant(Product product, ProductVariant variant) async {
    final shop = context.read<ShopController>();
    final success = await shop.archiveVariant(productId: product.id, variantId: variant.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${variant.label} archived' : shop.errorMessage ?? 'Unable to archive variant'),
      ),
    );
  }

  Future<void> _removeComboItem(Product product, ComboItem item) async {
    final shop = context.read<ShopController>();
    final success = await shop.removeComboItem(comboProductId: product.id, itemId: item.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${item.componentName} removed from combo' : shop.errorMessage ?? 'Unable to remove combo item'),
      ),
    );
  }

  Future<void> _showVariantEditor({
    required Product product,
    ProductVariant? variant,
  }) async {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: variant?.label ?? '');
    final priceController = TextEditingController(
      text: variant == null ? product.price.toStringAsFixed(0) : variant.price.toStringAsFixed(0),
    );
    final stockController = TextEditingController(
      text: variant == null ? product.stockQuantity.toString() : variant.stockQuantity.toString(),
    );
    var isActive = variant?.isActive ?? true;

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      variant == null ? 'Add variant' : 'Edit variant',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use variants for pack sizes, price ladders, and stock splits.',
                      style: const TextStyle(color: Color(0xFF6B5C4E), height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: 'Variant label'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a label';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final parsed = double.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(labelText: 'Stock quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid stock quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (value) {
                        setModalState(() {
                          isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final shop = context.read<ShopController>();
                        final ok = variant == null
                            ? await shop.createVariant(
                                productId: product.id,
                                label: labelController.text.trim(),
                                price: double.parse(priceController.text.trim()),
                                stockQuantity: int.parse(stockController.text.trim()),
                                isActive: isActive,
                              )
                            : await shop.updateVariant(
                                productId: product.id,
                                variantId: variant.id,
                                label: labelController.text.trim(),
                                price: double.parse(priceController.text.trim()),
                                stockQuantity: int.parse(stockController.text.trim()),
                                isActive: isActive,
                              );

                        if (!context.mounted) {
                          return;
                        }

                        if (ok) {
                          Navigator.of(context).pop(true);
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(shop.errorMessage ?? 'Unable to save variant')),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(variant == null ? 'Create Variant' : 'Save Variant'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    labelController.dispose();
    priceController.dispose();
    stockController.dispose();

    if (success == true) {
      await _loadVariants(forceRefresh: true);
    }
  }

  Future<void> _showComboItemEditor({
    required Product product,
    ComboItem? existingItem,
  }) async {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController(text: (existingItem?.quantity ?? 1).toString());
    String? selectedProductId = existingItem?.componentProductId;

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final shop = context.read<ShopController>();
        final candidates = shop.adminProducts.where((item) => item.id != product.id && item.isActive).toList();
        selectedProductId ??= candidates.isNotEmpty ? candidates.first.id : null;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  existingItem == null ? 'Add combo component' : 'Adjust combo component',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Build a curated bundle from active products in your catalog.',
                  style: TextStyle(color: Color(0xFF6B5C4E), height: 1.45),
                ),
                const SizedBox(height: 18),
                if (existingItem == null)
                  DropdownButtonFormField<String>(
                    value: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Component product'),
                    items: candidates
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text('${item.name} � Rs ${item.price.toStringAsFixed(0)}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      selectedProductId = value;
                    },
                    validator: (value) => value == null ? 'Select a component product' : null,
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(existingItem.componentName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('Rs ${existingItem.componentPrice.toStringAsFixed(0)} each'),
                    leading: const CircleAvatar(child: Icon(Icons.inventory_2_rounded)),
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity in combo'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final qty = int.parse(quantityController.text.trim());
                    final ok = existingItem == null
                        ? await shop.addComboItem(
                            comboProductId: product.id,
                            componentProductId: selectedProductId!,
                            quantity: qty,
                          )
                        : await shop.updateComboItem(
                            comboProductId: product.id,
                            itemId: existingItem.id,
                            quantity: qty,
                          );

                    if (!context.mounted) {
                      return;
                    }

                    if (ok) {
                      Navigator.of(context).pop(true);
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(shop.errorMessage ?? 'Unable to save combo item')),
                    );
                  },
                  icon: const Icon(Icons.account_tree_rounded),
                  label: Text(existingItem == null ? 'Add Component' : 'Save Quantity'),
                ),
              ],
            ),
          ),
        );
      },
    );

    quantityController.dispose();

    if (success == true) {
      await _loadComboItems(forceRefresh: true);
    }
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.product,
    required this.variants,
    required this.comboItems,
    required this.isAdminWorking,
    required this.onRefresh,
    required this.onEdit,
    required this.onArchiveToggle,
  });

  final Product product;
  final List<ProductVariant> variants;
  final List<ComboItem> comboItems;
  final bool isAdminWorking;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onArchiveToggle;

  @override
  Widget build(BuildContext context) {
    final comboValue = comboItems.fold<double>(0, (total, item) => total + item.componentPrice * item.quantity);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          AdminHeroBanner(
            eyebrow: 'Product Studio',
            title: product.name,
            subtitle: 'Tune inventory, pricing, variants, and bundle composition from one focused workspace.',
            stats: [
              AdminHeroStat(label: 'Price', value: 'Rs ${product.price.toStringAsFixed(0)}'),
              AdminHeroStat(label: 'Stock', value: '${product.stockQuantity}'),
              AdminHeroStat(label: 'Variants', value: '${variants.length}'),
              AdminHeroStat(label: 'Bundle', value: product.isCombo ? '${comboItems.length} items' : 'Not a combo'),
            ],
            accent: product.isCombo ? const Color(0xFF15803D) : const Color(0xFFB45309),
          ),
          const SizedBox(height: 20),
          ComboBlueprintCard(
            title: 'Merchandising snapshot',
            subtitle: 'A fast read of how this product is currently positioned in the catalog.',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 110, height: 110, child: ProductArtwork(product: product, radius: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(label: product.categoryLabel),
                          _Pill(label: product.isVeg ? 'Veg' : 'Non-veg'),
                          _Pill(label: product.isActive ? 'Active' : 'Archived'),
                          if (product.isBestseller) const _Pill(label: 'Bestseller'),
                          if (product.isNewArrival) const _Pill(label: 'New arrival'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.description.isEmpty ? 'No description yet.' : product.description,
                        style: const TextStyle(height: 1.45, color: Color(0xFF6B5C4E)),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: isAdminWorking ? null : onEdit,
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit Product'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: isAdminWorking ? null : onArchiveToggle,
                            icon: Icon(product.isActive ? Icons.archive_outlined : Icons.restore_rounded),
                            label: Text(product.isActive ? 'Archive' : 'Restore'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _MiniInsight(title: 'Review count', value: '${product.reviewCount}')),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniInsight(
                  title: 'Rating',
                  value: product.averageRating == null ? 'N/A' : product.averageRating!.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniInsight(title: 'Variant nodes', value: '${variants.length}')),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniInsight(
                  title: 'Bundle value',
                  value: product.isCombo ? 'Rs ${comboValue.toStringAsFixed(0)}' : 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantsTab extends StatelessWidget {
  const _VariantsTab({
    required this.product,
    required this.variants,
    required this.isLoading,
    required this.isBusy,
    required this.onRefresh,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
  });

  final Product product;
  final List<ProductVariant> variants;
  final bool isLoading;
  final bool isBusy;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<ProductVariant> onEdit;
  final ValueChanged<ProductVariant> onArchive;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          AdminHeroBanner(
            eyebrow: 'Variants',
            title: product.name,
            subtitle: 'Manage pack sizes, price points, and stock allocations for this product.',
            stats: [
              AdminHeroStat(label: 'Live variants', value: '${variants.length}'),
              AdminHeroStat(label: 'Base price', value: 'Rs ${product.price.toStringAsFixed(0)}'),
            ],
            action: FilledButton.icon(
              onPressed: isBusy ? null : onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Variant'),
            ),
          ),
          const SizedBox(height: 20),
          const SectionAccentLabel(label: 'Variant Matrix'),
          const SizedBox(height: 10),
          if (isLoading && variants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (variants.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No variants yet. Create one to sell this product in multiple sizes.'),
              ),
            )
          else
            ...variants.map(
              (variant) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant.label,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs ${variant.price.toStringAsFixed(0)} � ${variant.stockQuantity} in stock',
                                style: const TextStyle(color: Color(0xFF6B5C4E), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: isBusy ? null : () => onEdit(variant),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Edit'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: isBusy ? null : () => onArchive(variant),
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              label: const Text('Archive'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BundleTab extends StatelessWidget {
  const _BundleTab({
    required this.product,
    required this.items,
    required this.availableProducts,
    required this.isLoading,
    required this.isBusy,
    required this.onRefresh,
    required this.onConvertToCombo,
    required this.onAddItem,
    required this.onEditItem,
    required this.onRemoveItem,
  });

  final Product product;
  final List<ComboItem> items;
  final List<Product> availableProducts;
  final bool isLoading;
  final bool isBusy;
  final Future<void> Function() onRefresh;
  final VoidCallback onConvertToCombo;
  final VoidCallback onAddItem;
  final ValueChanged<ComboItem> onEditItem;
  final ValueChanged<ComboItem> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final componentValue = items.fold<double>(0, (sum, item) => sum + item.componentPrice * item.quantity);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          AdminHeroBanner(
            eyebrow: 'Bundle Composer',
            title: product.isCombo ? 'Combo blueprint' : 'Convert to combo',
            subtitle: product.isCombo
                ? 'Assemble a reusable bundle from active products and adjust quantities without leaving this workspace.'
                : 'This product is not yet a combo. Convert it first to unlock bundle composition.',
            stats: [
              AdminHeroStat(label: 'Components', value: '${items.length}'),
              AdminHeroStat(label: 'Catalog choices', value: '${availableProducts.length}'),
              AdminHeroStat(label: 'Bundle value', value: 'Rs ${componentValue.toStringAsFixed(0)}'),
            ],
            accent: const Color(0xFF15803D),
            action: FilledButton.icon(
              onPressed: isBusy ? null : (product.isCombo ? onAddItem : onConvertToCombo),
              icon: Icon(product.isCombo ? Icons.add_box_rounded : Icons.auto_awesome_motion_rounded),
              label: Text(product.isCombo ? 'Add Component' : 'Make Combo'),
            ),
          ),
          const SizedBox(height: 20),
          if (!product.isCombo)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Combo composition is only available when the product category is set to combo.',
                  style: TextStyle(height: 1.45),
                ),
              ),
            )
          else ...[
            ComboBlueprintCard(
              title: 'Bundle map',
              subtitle: 'Each component contributes directly to the final combo value and perceived assortment.',
              child: items.isEmpty
                  ? const Text('No components yet. Add products to start building the bundle.')
                  : Column(
                      children: items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.componentName,
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty ${item.quantity} � Rs ${(item.componentPrice * item.quantity).toStringAsFixed(0)}',
                                          style: const TextStyle(color: Color(0xFF6B5C4E)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            const SizedBox(height: 18),
            const SectionAccentLabel(label: 'Component List'),
            const SizedBox(height: 10),
            if (isLoading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No combo items yet. Add a component to compose the bundle.'),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.componentName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Quantity ${item.quantity} � Rs ${item.componentPrice.toStringAsFixed(0)} each',
                                  style: const TextStyle(color: Color(0xFF6B5C4E), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isBusy ? null : () => onEditItem(item),
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Adjust'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: isBusy ? null : () => onRemoveItem(item),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Remove'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MiniInsight extends StatelessWidget {
  const _MiniInsight({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF6B5C4E), fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
