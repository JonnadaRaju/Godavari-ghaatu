import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/shop_controller.dart';
import 'admin_dashboard_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    required this.onRequireAuth,
  });

  final Future<void> Function() onRequireAuth;

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        if (!shop.isAuthenticated || shop.currentUser == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 40, color: Color(0xFFB45309)),
                      const SizedBox(height: 14),
                      const Text(
                        'Sign in to view your account',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Once you log in, this Flutter app will load your profile, backend cart, and order history.',
                        style: TextStyle(height: 1.5, color: Color(0xFF6B5C4E)),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () {
                          onRequireAuth();
                        },
                        child: const Text('Sign in or register'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final user = shop.currentUser!;

        return RefreshIndicator(
          onRefresh: shop.refreshAccount,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFF6C478),
                            child: Text(
                              user.displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(user.email, style: const TextStyle(color: Color(0xFF6B5C4E))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0DB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Phone: ${user.phone}', style: const TextStyle(color: Color(0xFF6B5C4E))),
                      ],
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              shop.refreshAccount();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              shop.logout();
                            },
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (shop.isAdmin) ...[
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage store',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Admin tools now include a full product studio for variants, combo bundles, catalog updates, payment verification, and fulfilment status changes.',
                          style: TextStyle(height: 1.5, color: Color(0xFF6B5C4E)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const AdminDashboardScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                          label: const Text('Open Admin Tools'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent orders',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('${shop.orders.length} total'),
                ],
              ),
              const SizedBox(height: 12),
              if (shop.orders.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: const Text('No orders yet. Place your first order from the cart.'),
                  ),
                )
              else
                ...shop.orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _shortId(order.id),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _statusColor(order.status).withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: TextStyle(fontWeight: FontWeight.w800, color: _statusColor(order.status)),
                                  ),
                                ),
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

