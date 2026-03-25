import 'package:flutter/material.dart';

import '../models/product.dart';
import '../screens/account_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_detail_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String _catalogCategory = 'all';

  void _openCatalog([String? category]) {
    setState(() {
      _selectedIndex = 1;
      _catalogCategory = category ?? 'all';
    });
  }

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          onRequireAuth: () => _openAuth(context),
        ),
      ),
    );
  }

  Future<void> _openAuth(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = <String>['Godavari Ghaatu', 'Products', 'Cart', 'Account'];

    final pages = <Widget>[
      HomeScreen(
        onCategorySelected: _openCatalog,
        onProductSelected: (product) => _openProduct(context, product),
      ),
      CatalogScreen(
        selectedCategory: _catalogCategory,
        onCategoryChanged: (category) {
          setState(() {
            _catalogCategory = category;
          });
        },
        onProductSelected: (product) => _openProduct(context, product),
      ),
      CartScreen(
        onBrowseProducts: () => _openCatalog(),
        onRequireAuth: () => _openAuth(context),
      ),
      AccountScreen(onRequireAuth: () => _openAuth(context)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_selectedIndex])),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront_rounded), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_rounded), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Account'),
        ],
      ),
    );
  }
}
