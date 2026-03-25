import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_models.dart';
import '../models/payment_info.dart';
import '../models/product.dart';
import '../state/shop_controller.dart';
import '../widgets/product_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.onBrowseProducts,
    required this.onRequireAuth,
  });

  final VoidCallback onBrowseProducts;
  final Future<void> Function() onRequireAuth;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        if (!shop.isAuthenticated) {
          return _PromptCard(
            title: 'Sign in to manage your cart',
            body: 'The backend cart and order APIs are authenticated, so this Flutter app keeps cart and checkout behind login.',
            primaryLabel: 'Sign in',
            onPrimaryPressed: widget.onRequireAuth,
            secondaryLabel: 'Browse products',
            onSecondaryPressed: widget.onBrowseProducts,
          );
        }

        if (shop.cart.isEmpty) {
          return _PromptCard(
            title: 'Your cart is empty',
            body: 'Add products from the shop to create an order and fetch UPI payment details.',
            primaryLabel: 'Browse products',
            onPrimaryPressed: () async => widget.onBrowseProducts(),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  ...shop.cart.items.map((item) {
                    final product = shop.findProduct(item.productId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CartItemCard(
                        item: item,
                        product: product,
                        onIncrease: item.quantity < 99
                            ? () {
                                shop.updateCartItemQuantity(item.id, item.quantity + 1);
                              }
                            : null,
                        onDecrease: () {
                          if (item.quantity == 1) {
                            shop.removeCartItem(item.id);
                          } else {
                            shop.updateCartItemQuantity(item.id, item.quantity - 1);
                          }
                        },
                        onRemove: () {
                          shop.removeCartItem(item.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBF5),
                boxShadow: [
                  BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(label: 'Cart subtotal', value: 'Rs ${shop.cart.totalAmount.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      const Text(
                        'Delivery charge and tax are calculated by the backend during order creation.',
                        style: TextStyle(color: Color(0xFF6B5C4E), height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: shop.isPlacingOrder ? null : () {
                            _placeOrder();
                          },
                          icon: const Icon(Icons.payments_rounded),
                          label: Text(shop.isPlacingOrder ? 'Placing order...' : 'Place Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeOrder() async {
    final shop = context.read<ShopController>();
    final order = await shop.placeOrder();
    if (!mounted) {
      return;
    }

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shop.errorMessage ?? 'Unable to place order')),
      );
      return;
    }

    final paymentInfo = shop.lastPaymentInfo;
    if (paymentInfo != null) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PaymentInfoSheet(orderId: order.id, paymentInfo: paymentInfo),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order placed'),
          content: Text('Order ${order.id.substring(0, 8).toUpperCase()} was created successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.product,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItem item;
  final Product? product;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: ProductArtwork(
                product: product ??
                    Product(
                      id: item.productId,
                      name: 'Product',
                      description: '',
                      price: item.unitPrice,
                      stockQuantity: 0,
                      category: 'pickle',
                      isVeg: true,
                      isBestseller: false,
                      isNewArrival: false,
                      isActive: true,
                      reviewCount: 0,
                    ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Product ${item.productId.substring(0, 6)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  if (item.variantLabel != null && item.variantLabel!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.variantLabel!,
                      style: const TextStyle(color: Color(0xFF6B5C4E), fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Rs ${item.lineTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: onDecrease,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: onIncrease,
                        icon: const Icon(Icons.add_rounded),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B5C4E))),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final Future<void> Function() onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.shopping_bag_rounded, size: 40, color: Color(0xFFB45309)),
                const SizedBox(height: 14),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(body, style: const TextStyle(height: 1.5, color: Color(0xFF6B5C4E))),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    onPrimaryPressed();
                  },
                  child: Text(primaryLabel),
                ),
                if (secondaryLabel != null && onSecondaryPressed != null)
                  TextButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentInfoSheet extends StatelessWidget {
  const _PaymentInfoSheet({required this.orderId, required this.paymentInfo});

  final String orderId;
  final PaymentInfo paymentInfo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'UPI payment details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ${orderId.substring(0, 8).toUpperCase()} is ready for payment.',
              style: const TextStyle(color: Color(0xFF6B5C4E)),
            ),
            const SizedBox(height: 18),
            if (paymentInfo.qrBytes != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.memory(paymentInfo.qrBytes!, height: 220),
              ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(label: 'UPI ID', value: paymentInfo.upiId),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Payee', value: paymentInfo.upiName),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Amount', value: 'Rs ${paymentInfo.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Order code', value: paymentInfo.orderCode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...paymentInfo.instructions.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(step, style: const TextStyle(height: 1.45)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






