import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/state/shop_controller.dart';
import 'src/theme/app_theme.dart';
import 'src/widgets/app_shell.dart';

class GodavariApp extends StatefulWidget {
  const GodavariApp({super.key, this.controller});

  final ShopController? controller;

  @override
  State<GodavariApp> createState() => _GodavariAppState();
}

class _GodavariAppState extends State<GodavariApp> {
  late final ShopController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ShopController();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ShopController>.value(
      value: _controller,
      child: MaterialApp(
        title: 'Godavari Ghaatu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildTheme(),
        home: const _BootstrapScreen(),
      ),
    );
  }
}

class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shop, _) {
        if (shop.isBootstrapping) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF4E5), Color(0xFFFBE0B8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_dining_rounded, size: 64, color: Color(0xFF9A3412)),
                    SizedBox(height: 16),
                    Text(
                      'Godavari Ghaatu',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3F2A18),
                      ),
                    ),
                    SizedBox(height: 12),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        }

        return const AppShell();
      },
    );
  }
}
