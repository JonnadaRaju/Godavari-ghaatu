import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_models.dart';
import '../models/product.dart';
import '../state/shop_controller.dart';
import '../widgets/admin_art.dart';
import 'admin_product_form_screen.dart';
import 'admin_product_workspace_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopController>().refreshAdminData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Store Control Room'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Catalog'),
                Tab(text: 'Orders'),
              ],
            ),
          ),
          floatingActionButton: shop.isAdmin && _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: shop.isAdminWorking ? null : () => _openProductForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Product'),
                )
              : null,
          body: !shop.isAdmin
              ? const _BlockedView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _ProductsTab(
                      onEdit: _openProductForm,
                      onOpenStudio: _openWorkspace,
                    ),
                    const _OrdersTab(),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _openProductForm([Product? product]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminProductFormScreen(product: product),
      ),
    );
  }

  Future<void> _openWorkspace(Product product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminProductWorkspaceScreen(
          productId: product.id,
          initialProduct: product,
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  const _BlockedView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This section is available only to admin users authenticated against the backend.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({
    required this.onEdit,
    required this.onOpenStudio,
  });

  final Future<void> Function([Product? product]) onEdit;
  final Future<void> Function(Product product) onOpenStudio;

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        final activeProducts = shop.adminProducts.where((product) => product.isActive).length;
        final comboProducts = shop.adminProducts.where((product) => product.isCombo).length;
        final lowStockProducts = shop.adminProducts.where((product) => product.stockQuantity <= 10).length;

        if (shop.isAdminWorking && shop.adminProducts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: shop.refreshAdminData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              AdminHeroBanner(
                eyebrow: 'Catalog Ops',
                title: 'Shape the shelf, not just the rows.',
                subtitle: 'Use the studio workflow for deep product editing, variant ladders, and combo composition.',
                stats: [
                  AdminHeroStat(label: 'Products', value: '${shop.adminProducts.length}'),
                  AdminHeroStat(label: 'Active', value: '$activeProducts'),
                  AdminHeroStat(label: 'Combos', value: '$comboProducts'),
                  AdminHeroStat(label: 'Low stock', value: '$lowStockProducts'),
                ],
              ),
              const SizedBox(height: 20),
              const SectionAccentLabel(label: 'Catalog Grid'),
              const SizedBox(height: 10),
              if (shop.adminProducts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No products available yet.'),
                  ),
                )
              else
                ...shop.adminProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.description.isEmpty ? 'No description provided' : product.description,
                                        style: const TextStyle(color: Color(0xFF6B5C4E), height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _StatusBadge(
                                  label: product.isActive ? 'ACTIVE' : 'ARCHIVED',
                                  color: product.isActive ? const Color(0xFF15803D) : const Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusBadge(label: product.categoryLabel, color: const Color(0xFFB45309)),
                                _StatusBadge(label: product.isVeg ? 'VEG' : 'NON-VEG', color: const Color(0xFF0369A1)),
                                if (product.isBestseller)
                                  const _StatusBadge(label: 'BESTSELLER', color: Color(0xFF7C3AED)),
                                if (product.isNewArrival)
                                  const _StatusBadge(label: 'NEW', color: Color(0xFFEA580C)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  'Rs ${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text('Stock: ${product.stockQuantity}'),
                                const Spacer(),
                                if (product.stockQuantity <= 10)
                                  const Text(
                                    'Needs restock',
                                    style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w800),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => onOpenStudio(product),
                                  icon: const Icon(Icons.space_dashboard_rounded),
                                  label: const Text('Open Studio'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => onEdit(product),
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text('Quick Edit'),
                                ),
                                if (product.isActive)
                                  FilledButton.tonalIcon(
                                    onPressed: shop.isAdminWorking ? null : () => _confirmArchive(context, product),
                                    icon: const Icon(Icons.archive_outlined),
                                    label: const Text('Archive'),
                                  )
                                else
                                  FilledButton.tonalIcon(
                                    onPressed: shop.isAdminWorking ? null : () => _restore(context, product.id),
                                    icon: const Icon(Icons.restore_rounded),
                                    label: const Text('Restore'),
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
      },
    );
  }

  Future<void> _confirmArchive(BuildContext context, Product product) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive product'),
        content: Text('Archive ${product.name}? This uses the backend delete endpoint and marks it inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (approved != true || !context.mounted) {
      return;
    }

    final success = await context.read<ShopController>().archiveProduct(product.id);
    if (!context.mounted) {
      return;
    }

    final message = success
        ? '${product.name} archived'
        : context.read<ShopController>().errorMessage ?? 'Unable to archive product';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restore(BuildContext context, String productId) async {
    final success = await context.read<ShopController>().restoreProduct(productId);
    if (!context.mounted) {
      return;
    }

    final message = success
        ? 'Product restored'
        : context.read<ShopController>().errorMessage ?? 'Unable to restore product';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        final pendingCount = shop.orders.where((order) => order.status == 'PENDING').length;
        final shippingCount = shop.orders.where((order) => order.status == 'SHIPPED').length;
        final packedCount = shop.orders.where((order) => order.status == 'PACKED').length;

        return RefreshIndicator(
          onRefresh: shop.refreshAdminData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              AdminHeroBanner(
                eyebrow: 'Fulfilment',
                title: 'Move orders through the lane with intent.',
                subtitle: 'Verify payment first, then pack, ship, and deliver in the same sequence enforced by the backend.',
                stats: [
                  AdminHeroStat(label: 'Orders', value: '${shop.orders.length}'),
                  AdminHeroStat(label: 'Pending', value: '$pendingCount'),
                  AdminHeroStat(label: 'Packed', value: '$packedCount'),
                  AdminHeroStat(label: 'Shipping', value: '$shippingCount'),
                ],
                accent: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 20),
              const SectionAccentLabel(label: 'Order Lane'),
              const SizedBox(height: 10),
              if (shop.orders.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No orders available yet.'),
                  ),
                )
              else
                ...shop.orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _shortId(order.id),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                _StatusBadge(label: order.status, color: _statusColor(order.status)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Created: ${order.createdAt.toLocal()}',
                              style: const TextStyle(color: Color(0xFF6B5C4E)),
                            ),
                            const SizedBox(height: 16),
                            if (_labelForOrderAction(order) != null)
                              FilledButton.icon(
                                onPressed: shop.isAdminWorking ? null : () => _runOrderAction(context, order),
                                icon: Icon(_iconForOrderAction(order.status)),
                                label: Text(_labelForOrderAction(order)!),
                              )
                            else
                              const Text(
                                'No further admin action available for this order.',
                                style: TextStyle(color: Color(0xFF6B5C4E)),
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
      },
    );
  }

  Future<void> _runOrderAction(BuildContext context, OrderSummary order) async {
    final shop = context.read<ShopController>();
    bool success;

    switch (order.status) {
      case 'PENDING':
        success = await shop.verifyPayment(order.id);
        break;
      case 'PAID':
        success = await shop.updateAdminOrderStatus(order.id, 'PACKED');
        break;
      case 'PACKED':
        success = await shop.updateAdminOrderStatus(order.id, 'SHIPPED');
        break;
      case 'SHIPPED':
        success = await shop.updateAdminOrderStatus(order.id, 'DELIVERED');
        break;
      default:
        success = false;
        break;
    }

    if (!context.mounted) {
      return;
    }

    final message = success
        ? '${_shortId(order.id)} updated successfully'
        : shop.errorMessage ?? 'Unable to update order';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _labelForOrderAction(OrderSummary order) {
    switch (order.status) {
      case 'PENDING':
        return 'Verify Payment';
      case 'PAID':
        return 'Pack Order';
      case 'PACKED':
        return 'Ship Order';
      case 'SHIPPED':
        return 'Mark Delivered';
      default:
        return null;
    }
  }

  IconData _iconForOrderAction(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.verified_rounded;
      case 'PAID':
        return Icons.inventory_2_rounded;
      case 'PACKED':
        return Icons.local_shipping_rounded;
      case 'SHIPPED':
        return Icons.done_all_rounded;
      default:
        return Icons.check_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

String _shortId(String value) {
  return value.length <= 8 ? value.toUpperCase() : value.substring(0, 8).toUpperCase();
}

Color _statusColor(String status) {
  switch (status) {
    case 'PAID':
      return const Color(0xFF0369A1);
    case 'PACKED':
      return const Color(0xFF7C3AED);
    case 'SHIPPED':
      return const Color(0xFF2563EB);
    case 'DELIVERED':
      return const Color(0xFF15803D);
    case 'CANCELLED':
      return const Color(0xFFB91C1C);
    default:
      return const Color(0xFFB45309);
  }
}
