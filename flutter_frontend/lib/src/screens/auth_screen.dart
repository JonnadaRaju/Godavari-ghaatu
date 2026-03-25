import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/shop_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  late final TextEditingController _loginEmailController;
  late final TextEditingController _loginPasswordController;
  late final TextEditingController _registerNameController;
  late final TextEditingController _registerEmailController;
  late final TextEditingController _registerPhoneController;
  late final TextEditingController _registerPasswordController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loginEmailController = TextEditingController();
    _loginPasswordController = TextEditingController();
    _registerNameController = TextEditingController();
    _registerEmailController = TextEditingController();
    _registerPhoneController = TextEditingController();
    _registerPasswordController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Account access'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Login'),
                Tab(text: 'Register'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildLoginTab(context, shop),
              _buildRegisterTab(context, shop),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginTab(BuildContext context, ShopController shop) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Form(
          key: _loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text('Log in to sync your cart, orders, and payment details.'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _loginEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => _validateEmail(value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _loginPasswordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => _validatePassword(value),
              ),
              if (shop.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(shop.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: shop.isAuthenticating ? null : () {
                    _submitLogin();
                  },
                  child: Text(shop.isAuthenticating ? 'Signing in...' : 'Login'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab(BuildContext context, ShopController shop) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Form(
          key: _registerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create an account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text('Register against the FastAPI auth endpoint and immediately sign in.'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _registerNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _registerEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => _validateEmail(value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _registerPhoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _registerPasswordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => _validatePassword(value),
              ),
              if (shop.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(shop.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: shop.isAuthenticating ? null : () {
                    _submitRegister();
                  },
                  child: Text(shop.isAuthenticating ? 'Creating account...' : 'Register'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    final success = await context.read<ShopController>().login(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    final success = await context.read<ShopController>().register(
          fullName: _registerNameController.text.trim(),
          email: _registerEmailController.text.trim(),
          phone: _registerPhoneController.text.trim().isEmpty ? null : _registerPhoneController.text.trim(),
          password: _registerPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || !text.contains('@')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 8) {
      return 'Minimum 8 characters';
    }
    return null;
  }
}

