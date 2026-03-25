import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/shop_controller.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.product});

  final Product? product;

  bool get isEditing => product != null;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;

  late String _category;
  late bool _isVeg;
  late bool _isBestseller;
  late bool _isNewArrival;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(text: product == null ? '' : product.price.toStringAsFixed(2));
    _stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '0');
    _imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    _category = product?.category ?? 'pickle';
    _isVeg = product?.isVeg ?? true;
    _isBestseller = product?.isBestseller ?? false;
    _isNewArrival = product?.isNewArrival ?? false;
    _isActive = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isEditing ? 'Edit Product' : 'Create Product'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
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
                  controller: _stockController,
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'pickle', child: Text('Pickle')),
                    DropdownMenuItem(value: 'spice', child: Text('Spice')),
                    DropdownMenuItem(value: 'laddu', child: Text('Laddu')),
                    DropdownMenuItem(value: 'combo', child: Text('Combo')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vegetarian'),
                  value: _isVeg,
                  onChanged: (value) {
                    setState(() {
                      _isVeg = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bestseller'),
                  value: _isBestseller,
                  onChanged: (value) {
                    setState(() {
                      _isBestseller = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('New arrival'),
                  value: _isNewArrival,
                  onChanged: (value) {
                    setState(() {
                      _isNewArrival = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                if (shop.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      shop.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: shop.isAdminWorking
                        ? null
                        : () {
                            _submit();
                          },
                    icon: const Icon(Icons.save_rounded),
                    label: Text(shop.isAdminWorking ? 'Saving...' : 'Save Product'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'stock_quantity': int.parse(_stockController.text.trim()),
      'image_url': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      'category': _category,
      'is_veg': _isVeg,
      'is_bestseller': _isBestseller,
      'is_new_arrival': _isNewArrival,
      'is_active': _isActive,
    };

    final shop = context.read<ShopController>();
    final success = widget.isEditing
        ? await shop.updateProduct(widget.product!.id, payload)
        : await shop.createProduct(payload);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(shop.errorMessage ?? 'Unable to save product')),
    );
  }
}
