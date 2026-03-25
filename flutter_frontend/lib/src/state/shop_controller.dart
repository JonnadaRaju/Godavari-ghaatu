import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_models.dart';
import '../models/combo_item.dart';
import '../models/order_models.dart';
import '../models/payment_info.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class ShopController extends ChangeNotifier {
  ShopController({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        _isPreviewMode = false;

  ShopController.preview({bool asAdmin = false})
      : _apiClient = ApiClient(),
        _isPreviewMode = true {
    _isBootstrapping = false;
    _products = Product.previewItems();
    _adminProducts = List<Product>.from(_products);

    _variantCache['1'] = const [
      ProductVariant(
        id: 'variant-1a',
        productId: '1',
        label: '250g',
        price: 250,
        stockQuantity: 24,
        isActive: true,
      ),
      ProductVariant(
        id: 'variant-1b',
        productId: '1',
        label: '500g',
        price: 460,
        stockQuantity: 15,
        isActive: true,
      ),
    ];

    _variantCache['3'] = const [
      ProductVariant(
        id: 'variant-3a',
        productId: '3',
        label: 'Pack of 6',
        price: 320,
        stockQuantity: 12,
        isActive: true,
      ),
    ];

    _comboItemCache['4'] = const [
      ComboItem(
        id: 'combo-4a',
        comboProductId: '4',
        componentProductId: '1',
        quantity: 1,
        componentName: 'Mango Pickle',
        componentPrice: 250,
      ),
      ComboItem(
        id: 'combo-4b',
        comboProductId: '4',
        componentProductId: '2',
        quantity: 1,
        componentName: 'Sesame Podi',
        componentPrice: 180,
      ),
      ComboItem(
        id: 'combo-4c',
        comboProductId: '4',
        componentProductId: '3',
        quantity: 1,
        componentName: 'Dry Fruit Laddu',
        componentPrice: 320,
      ),
    ];

    if (asAdmin) {
      _token = 'preview-token';
      _currentUser = AppUser(
        id: 'preview-admin',
        email: 'admin@godavari.local',
        role: 'admin',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        fullName: 'Preview Admin',
        phone: '9999999999',
      );
      _orders = <OrderSummary>[
        OrderSummary(
          id: 'preview-order-1001',
          status: 'PENDING',
          totalAmount: 840,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        OrderSummary(
          id: 'preview-order-1002',
          status: 'PAID',
          totalAmount: 560,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        OrderSummary(
          id: 'preview-order-1003',
          status: 'PACKED',
          totalAmount: 610,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    }
  }

  static const _tokenKey = 'auth_token';

  final ApiClient _apiClient;
  final bool _isPreviewMode;

  SharedPreferences? _preferences;
  bool _isBootstrapping = true;
  bool _isProductsLoading = false;
  bool _isAuthenticating = false;
  bool _isCartBusy = false;
  bool _isPlacingOrder = false;
  bool _isAdminWorking = false;
  String? _token;
  String? _errorMessage;
  AppUser? _currentUser;
  CartData _cart = const CartData.empty();
  List<Product> _products = <Product>[];
  List<Product> _adminProducts = <Product>[];
  List<OrderSummary> _orders = <OrderSummary>[];
  final Map<String, List<ProductVariant>> _variantCache = <String, List<ProductVariant>>{};
  final Map<String, List<ComboItem>> _comboItemCache = <String, List<ComboItem>>{};
  PaymentInfo? _lastPaymentInfo;

  bool get isBootstrapping => _isBootstrapping;
  bool get isProductsLoading => _isProductsLoading;
  bool get isAuthenticating => _isAuthenticating;
  bool get isCartBusy => _isCartBusy;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isAdminWorking => _isAdminWorking;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isPreviewMode => _isPreviewMode;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;
  CartData get cart => _cart;
  List<Product> get products => List<Product>.unmodifiable(_products);
  List<Product> get adminProducts => List<Product>.unmodifiable(_adminProducts);
  List<OrderSummary> get orders => List<OrderSummary>.unmodifiable(_orders);
  PaymentInfo? get lastPaymentInfo => _lastPaymentInfo;

  List<Product> get featuredProducts {
    final featured = _products
        .where((product) => product.isBestseller || product.isNewArrival)
        .toList();
    if (featured.isNotEmpty) {
      return featured.take(6).toList();
    }
    return _products.take(6).toList();
  }

  List<ProductVariant> variantsFor(String productId) {
    return List<ProductVariant>.unmodifiable(_variantCache[productId] ?? const <ProductVariant>[]);
  }

  List<ComboItem> comboItemsFor(String productId) {
    return List<ComboItem>.unmodifiable(_comboItemCache[productId] ?? const <ComboItem>[]);
  }

  Future<void> initialize() async {
    if (_isPreviewMode) {
      _isBootstrapping = false;
      notifyListeners();
      return;
    }

    if (!_isBootstrapping) {
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    _token = _preferences?.getString(_tokenKey);

    await loadProducts(silent: true);

    if (isAuthenticated) {
      try {
        final userJson = await _apiClient.get('/api/v1/users/me', token: _token);
        _currentUser = AppUser.fromJson(Map<String, dynamic>.from(userJson as Map));
        await Future.wait(<Future<void>>[
          loadCart(silent: true),
          loadOrders(silent: true),
          if (isAdmin) loadAdminProducts(silent: true),
        ]);
      } on ApiException {
        await logout(notify: false);
      }
    }

    _isBootstrapping = false;
    notifyListeners();
  }

  Future<void> loadProducts({bool silent = false}) async {
    if (_isPreviewMode) {
      _syncPreviewVisibleProducts();
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    if (!silent) {
      _isProductsLoading = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.get(
        '/api/v1/products',
        queryParameters: <String, String>{'limit': '100'},
      );

      final productsJson = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _products = productsJson.map(Product.fromJson).toList();
      _clearError();
    } catch (error) {
      _setError(error);
    } finally {
      _isProductsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminProducts({bool silent = false}) async {
    if (!isAdmin) {
      _adminProducts = <Product>[];
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    if (_isPreviewMode) {
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    if (!silent) {
      _isAdminWorking = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.get(
        '/api/v1/products',
        token: _token,
        queryParameters: <String, String>{
          'limit': '100',
          'active_only': 'false',
        },
      );
      final productsJson = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _adminProducts = productsJson.map(Product.fromJson).toList();
      _clearError();
    } catch (error) {
      _setError(error);
    } finally {
      _isAdminWorking = false;
      notifyListeners();
    }
  }

  Future<Product?> getProductById(String productId) async {
    final existing = findProduct(productId);
    if (existing != null) {
      return existing;
    }

    if (_isPreviewMode) {
      return null;
    }

    try {
      final response = await _apiClient.get('/api/v1/products/$productId');
      final product = Product.fromJson(Map<String, dynamic>.from(response as Map));
      _products = <Product>[..._products.where((item) => item.id != product.id), product];
      notifyListeners();
      return product;
    } catch (error) {
      _setError(error);
      notifyListeners();
      return null;
    }
  }

  Product? findProduct(String productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    for (final product in _adminProducts) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  Future<List<ProductVariant>> loadVariants(String productId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _variantCache.containsKey(productId)) {
      return _variantCache[productId]!;
    }

    if (_isPreviewMode) {
      return _variantCache[productId] ?? <ProductVariant>[];
    }

    try {
      final response = await _apiClient.get('/api/v1/products/$productId/variants');
      final variantsJson = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final variants = variantsJson.map(ProductVariant.fromJson).toList();
      _variantCache[productId] = variants;
      notifyListeners();
      return variants;
    } catch (error) {
      _setError(error);
      notifyListeners();
      return <ProductVariant>[];
    }
  }

  Future<List<ComboItem>> loadComboItems(String productId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _comboItemCache.containsKey(productId)) {
      return _comboItemCache[productId]!;
    }

    if (_isPreviewMode) {
      return _comboItemCache[productId] ?? <ComboItem>[];
    }

    try {
      final response = await _apiClient.get('/api/v1/products/$productId/combo-items');
      final itemsJson = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final items = itemsJson.map(ComboItem.fromJson).toList();
      _comboItemCache[productId] = items;
      notifyListeners();
      return items;
    } catch (error) {
      _setError(error);
      notifyListeners();
      return <ComboItem>[];
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      final loginResponse = await _apiClient.post(
        '/api/v1/auth/login',
        body: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );

      _token = (loginResponse as Map<String, dynamic>)['access_token']?.toString();
      await _preferences?.setString(_tokenKey, _token ?? '');

      final userJson = await _apiClient.get('/api/v1/users/me', token: _token);
      _currentUser = AppUser.fromJson(Map<String, dynamic>.from(userJson as Map));

      await Future.wait(<Future<void>>[
        loadCart(silent: true),
        loadOrders(silent: true),
        if (isAdmin) loadAdminProducts(silent: true),
      ]);

      _clearError();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      await _apiClient.post(
        '/api/v1/auth/register',
        body: <String, dynamic>{
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );
      _clearError();
    } catch (error) {
      _setError(error);
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }

    _isAuthenticating = false;
    notifyListeners();
    return login(email: email, password: password);
  }

  Future<void> logout({bool notify = true}) async {
    _token = null;
    _currentUser = null;
    _orders = <OrderSummary>[];
    _adminProducts = <Product>[];
    _cart = const CartData.empty();
    _lastPaymentInfo = null;
    if (!_isPreviewMode) {
      await _preferences?.remove(_tokenKey);
    }
    _clearError();
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> loadCart({bool silent = false}) async {
    if (!isAuthenticated) {
      _cart = const CartData.empty();
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    if (_isPreviewMode) {
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    if (!silent) {
      _isCartBusy = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.get('/api/v1/cart', token: _token);
      _cart = CartData.fromJson(Map<String, dynamic>.from(response as Map));
      await _hydrateProductsForIds(_cart.items.map((item) => item.productId).toSet());
      _clearError();
    } catch (error) {
      _setError(error);
    } finally {
      _isCartBusy = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart({
    required String productId,
    int quantity = 1,
    String? variantId,
  }) async {
    if (!isAuthenticated) {
      _setError(const ApiException('Please sign in to add items to your cart.'));
      notifyListeners();
      return false;
    }

    if (_isPreviewMode) {
      _setError(const ApiException('Preview mode does not persist cart changes.'));
      notifyListeners();
      return false;
    }

    _isCartBusy = true;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/api/v1/cart/items',
        token: _token,
        body: <String, dynamic>{
          'product_id': productId,
          'quantity': quantity,
          if (variantId != null) 'variant_id': variantId,
        },
      );

      _cart = CartData.fromJson(Map<String, dynamic>.from(response as Map));
      await _hydrateProductsForIds(<String>{productId});
      _clearError();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isCartBusy = false;
      notifyListeners();
    }
  }

  Future<bool> updateCartItemQuantity(String itemId, int quantity) async {
    if (!isAuthenticated || _isPreviewMode) {
      return false;
    }

    _isCartBusy = true;
    notifyListeners();

    try {
      final response = await _apiClient.put(
        '/api/v1/cart/items/$itemId',
        token: _token,
        body: <String, dynamic>{'quantity': quantity},
      );
      _cart = CartData.fromJson(Map<String, dynamic>.from(response as Map));
      _clearError();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isCartBusy = false;
      notifyListeners();
    }
  }

  Future<bool> removeCartItem(String itemId) async {
    if (!isAuthenticated || _isPreviewMode) {
      return false;
    }

    _isCartBusy = true;
    notifyListeners();

    try {
      final response = await _apiClient.delete(
        '/api/v1/cart/items/$itemId',
        token: _token,
      );
      _cart = CartData.fromJson(Map<String, dynamic>.from(response as Map));
      _clearError();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isCartBusy = false;
      notifyListeners();
    }
  }

  Future<OrderSummary?> placeOrder() async {
    if (!isAuthenticated) {
      _setError(const ApiException('Please sign in before placing an order.'));
      notifyListeners();
      return null;
    }

    if (_isPreviewMode) {
      _setError(const ApiException('Preview mode does not create real orders.'));
      notifyListeners();
      return null;
    }

    _isPlacingOrder = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/api/v1/orders', token: _token);
      final order = OrderSummary.fromJson(Map<String, dynamic>.from(response as Map));
      _lastPaymentInfo = await fetchPaymentInfo(order.id, silent: true);
      await Future.wait(<Future<void>>[
        loadCart(silent: true),
        loadOrders(silent: true),
      ]);
      _clearError();
      return order;
    } catch (error) {
      _setError(error);
      return null;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!isAuthenticated) {
      _orders = <OrderSummary>[];
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    if (_isPreviewMode) {
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    try {
      final response = await _apiClient.get('/api/v1/orders', token: _token);
      final ordersJson = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _orders = ordersJson.map(OrderSummary.fromJson).toList();
      _clearError();
    } catch (error) {
      _setError(error);
    } finally {
      notifyListeners();
    }
  }

  Future<PaymentInfo?> fetchPaymentInfo(String orderId, {bool silent = false}) async {
    if (!isAuthenticated || _isPreviewMode) {
      return null;
    }

    try {
      final response = await _apiClient.get('/api/v1/payments/upi/$orderId', token: _token);
      final payment = PaymentInfo.fromJson(Map<String, dynamic>.from(response as Map));
      _lastPaymentInfo = payment;
      if (!silent) {
        notifyListeners();
      }
      return payment;
    } catch (error) {
      if (!silent) {
        _setError(error);
        notifyListeners();
      }
      return null;
    }
  }

  Future<void> refreshAccount() async {
    if (!isAuthenticated) {
      return;
    }

    if (_isPreviewMode) {
      notifyListeners();
      return;
    }

    try {
      final userJson = await _apiClient.get('/api/v1/users/me', token: _token);
      _currentUser = AppUser.fromJson(Map<String, dynamic>.from(userJson as Map));
      await Future.wait(<Future<void>>[
        loadOrders(silent: true),
        if (isAdmin) loadAdminProducts(silent: true),
      ]);
      _clearError();
    } catch (error) {
      _setError(error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshAdminData() async {
    if (!isAdmin) {
      return;
    }

    if (_isPreviewMode) {
      notifyListeners();
      return;
    }

    _isAdminWorking = true;
    notifyListeners();

    try {
      await Future.wait(<Future<void>>[
        loadAdminProducts(silent: true),
        loadOrders(silent: true),
      ]);
      _clearError();
    } catch (error) {
      _setError(error);
    } finally {
      _isAdminWorking = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> payload) async {
    if (_isPreviewMode) {
      return _previewCreateProduct(payload);
    }

    return _runAdminMutation(
      () => _apiClient.post('/api/v1/products', token: _token, body: payload),
      afterSuccess: () async {
        await Future.wait(<Future<void>>[
          loadAdminProducts(silent: true),
          loadProducts(silent: true),
        ]);
      },
    );
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> payload) async {
    if (_isPreviewMode) {
      return _previewUpdateProduct(productId, payload);
    }

    return _runAdminMutation(
      () => _apiClient.put('/api/v1/products/$productId', token: _token, body: payload),
      afterSuccess: () async {
        await Future.wait(<Future<void>>[
          loadAdminProducts(silent: true),
          loadProducts(silent: true),
        ]);
      },
    );
  }

  Future<bool> archiveProduct(String productId) async {
    if (_isPreviewMode) {
      return _previewArchiveProduct(productId, false);
    }

    return _runAdminMutation(
      () => _apiClient.delete('/api/v1/products/$productId', token: _token),
      afterSuccess: () async {
        await Future.wait(<Future<void>>[
          loadAdminProducts(silent: true),
          loadProducts(silent: true),
        ]);
      },
    );
  }

  Future<bool> restoreProduct(String productId) async {
    if (_isPreviewMode) {
      return _previewArchiveProduct(productId, true);
    }

    return updateProduct(productId, <String, dynamic>{'is_active': true});
  }

  Future<bool> createVariant({
    required String productId,
    required String label,
    required double price,
    required int stockQuantity,
    bool isActive = true,
  }) async {
    if (_isPreviewMode) {
      return _previewCreateVariant(
        productId: productId,
        label: label,
        price: price,
        stockQuantity: stockQuantity,
        isActive: isActive,
      );
    }

    return _runAdminMutation(
      () => _apiClient.post(
        '/api/v1/products/$productId/variants',
        token: _token,
        body: <String, dynamic>{
          'label': label,
          'price': price,
          'stock_quantity': stockQuantity,
          'is_active': isActive,
        },
      ),
      afterSuccess: () => loadVariants(productId, forceRefresh: true),
    );
  }

  Future<bool> updateVariant({
    required String productId,
    required String variantId,
    required String label,
    required double price,
    required int stockQuantity,
    required bool isActive,
  }) async {
    if (_isPreviewMode) {
      return _previewUpdateVariant(
        productId: productId,
        variantId: variantId,
        label: label,
        price: price,
        stockQuantity: stockQuantity,
        isActive: isActive,
      );
    }

    return _runAdminMutation(
      () => _apiClient.put(
        '/api/v1/products/$productId/variants/$variantId',
        token: _token,
        body: <String, dynamic>{
          'label': label,
          'price': price,
          'stock_quantity': stockQuantity,
          'is_active': isActive,
        },
      ),
      afterSuccess: () => loadVariants(productId, forceRefresh: true),
    );
  }

  Future<bool> archiveVariant({
    required String productId,
    required String variantId,
  }) async {
    if (_isPreviewMode) {
      return _previewArchiveVariant(productId: productId, variantId: variantId);
    }

    return _runAdminMutation(
      () => _apiClient.delete(
        '/api/v1/products/$productId/variants/$variantId',
        token: _token,
      ),
      afterSuccess: () => loadVariants(productId, forceRefresh: true),
    );
  }

  Future<bool> addComboItem({
    required String comboProductId,
    required String componentProductId,
    required int quantity,
  }) async {
    if (_isPreviewMode) {
      return _previewAddComboItem(
        comboProductId: comboProductId,
        componentProductId: componentProductId,
        quantity: quantity,
      );
    }

    return _runAdminMutation(
      () => _apiClient.post(
        '/api/v1/products/$comboProductId/combo-items',
        token: _token,
        body: <String, dynamic>{
          'component_product_id': componentProductId,
          'quantity': quantity,
        },
      ),
      afterSuccess: () => loadComboItems(comboProductId, forceRefresh: true),
    );
  }

  Future<bool> updateComboItem({
    required String comboProductId,
    required String itemId,
    required int quantity,
  }) async {
    if (_isPreviewMode) {
      return _previewUpdateComboItem(
        comboProductId: comboProductId,
        itemId: itemId,
        quantity: quantity,
      );
    }

    return _runAdminMutation(
      () => _apiClient.put(
        '/api/v1/products/$comboProductId/combo-items/$itemId',
        token: _token,
        body: <String, dynamic>{'quantity': quantity},
      ),
      afterSuccess: () => loadComboItems(comboProductId, forceRefresh: true),
    );
  }

  Future<bool> removeComboItem({
    required String comboProductId,
    required String itemId,
  }) async {
    if (_isPreviewMode) {
      return _previewRemoveComboItem(comboProductId: comboProductId, itemId: itemId);
    }

    return _runAdminMutation(
      () => _apiClient.delete(
        '/api/v1/products/$comboProductId/combo-items/$itemId',
        token: _token,
      ),
      afterSuccess: () => loadComboItems(comboProductId, forceRefresh: true),
    );
  }

  Future<bool> verifyPayment(String orderId) async {
    if (_isPreviewMode) {
      return _previewUpdateOrderStatus(orderId, 'PAID');
    }

    return _runAdminMutation(
      () => _apiClient.post('/api/v1/payments/verify/$orderId', token: _token),
      afterSuccess: () => loadOrders(silent: true),
    );
  }

  Future<bool> updateAdminOrderStatus(String orderId, String newStatus) async {
    if (_isPreviewMode) {
      return _previewUpdateOrderStatus(orderId, newStatus);
    }

    final suffix = _statusSuffix(newStatus);
    if (suffix == null) {
      _setError(const ApiException('Unsupported admin order transition.'));
      notifyListeners();
      return false;
    }

    return _runAdminMutation(
      () => _apiClient.patch('/api/v1/orders/$orderId/$suffix', token: _token),
      afterSuccess: () => loadOrders(silent: true),
    );
  }

  void clearErrorMessage() {
    _clearError();
    notifyListeners();
  }

  Future<bool> _runAdminMutation(
    Future<dynamic> Function() action, {
    Future<void> Function()? afterSuccess,
  }) async {
    if (!isAdmin) {
      _setError(const ApiException('Admin access is required for this action.'));
      notifyListeners();
      return false;
    }

    _isAdminWorking = true;
    notifyListeners();

    try {
      await action();
      if (afterSuccess != null) {
        await afterSuccess();
      }
      _clearError();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isAdminWorking = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateProductsForIds(Set<String> productIds) async {
    if (_isPreviewMode || productIds.isEmpty) {
      return;
    }

    final missingIds = productIds.where((productId) => findProduct(productId) == null).toList();
    if (missingIds.isEmpty) {
      return;
    }

    for (final productId in missingIds) {
      try {
        final response = await _apiClient.get('/api/v1/products/$productId');
        final product = Product.fromJson(Map<String, dynamic>.from(response as Map));

        final visibleIndex = _products.indexWhere((item) => item.id == product.id);
        if (visibleIndex >= 0) {
          _products[visibleIndex] = product;
        } else {
          _products = <Product>[..._products, product];
        }

        final adminIndex = _adminProducts.indexWhere((item) => item.id == product.id);
        if (adminIndex >= 0) {
          _adminProducts[adminIndex] = product;
        }
      } catch (_) {
        // Ignore hydration failures for individual products and keep the cart usable.
      }
    }
  }

  void _syncPreviewVisibleProducts() {
    _products = _adminProducts.where((product) => product.isActive).toList()
      ..sort((left, right) => left.name.compareTo(right.name));
  }

  bool _previewCreateProduct(Map<String, dynamic> payload) {
    final product = Product(
      id: 'preview-product-${DateTime.now().microsecondsSinceEpoch}',
      name: (payload['name'] as String?)?.trim().isNotEmpty == true
          ? (payload['name'] as String).trim()
          : 'Untitled Product',
      description: (payload['description'] as String?)?.trim() ?? '',
      price: (payload['price'] as num?)?.toDouble() ?? 0,
      stockQuantity: (payload['stock_quantity'] as num?)?.toInt() ?? 0,
      category: (payload['category'] as String?) ?? 'pickle',
      isVeg: payload['is_veg'] as bool? ?? true,
      isBestseller: payload['is_bestseller'] as bool? ?? false,
      isNewArrival: payload['is_new_arrival'] as bool? ?? false,
      isActive: payload['is_active'] as bool? ?? true,
      imageUrl: payload['image_url'] as String?,
      averageRating: null,
      reviewCount: 0,
    );

    _adminProducts = <Product>[product, ..._adminProducts];
    if (product.isCombo) {
      _comboItemCache.putIfAbsent(product.id, () => <ComboItem>[]);
    }
    _variantCache.putIfAbsent(product.id, () => <ProductVariant>[]);
    _syncPreviewVisibleProducts();
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewUpdateProduct(String productId, Map<String, dynamic> payload) {
    final index = _adminProducts.indexWhere((product) => product.id == productId);
    if (index < 0) {
      _setError(const ApiException('Product not found.'));
      notifyListeners();
      return false;
    }

    final current = _adminProducts[index];
    final updated = current.copyWith(
      name: (payload['name'] as String?)?.trim().isNotEmpty == true
          ? (payload['name'] as String).trim()
          : current.name,
      description: payload.containsKey('description') ? (payload['description'] as String?) ?? '' : current.description,
      price: payload['price'] == null ? current.price : (payload['price'] as num).toDouble(),
      stockQuantity: payload['stock_quantity'] == null ? current.stockQuantity : (payload['stock_quantity'] as num).toInt(),
      category: (payload['category'] as String?) ?? current.category,
      isVeg: payload['is_veg'] as bool? ?? current.isVeg,
      isBestseller: payload['is_bestseller'] as bool? ?? current.isBestseller,
      isNewArrival: payload['is_new_arrival'] as bool? ?? current.isNewArrival,
      isActive: payload['is_active'] as bool? ?? current.isActive,
      imageUrl: payload.containsKey('image_url') ? payload['image_url'] as String? : current.imageUrl,
    );

    _adminProducts[index] = updated;
    if (updated.isCombo) {
      _comboItemCache.putIfAbsent(updated.id, () => <ComboItem>[]);
    } else {
      _comboItemCache.remove(updated.id);
    }
    _variantCache.putIfAbsent(updated.id, () => <ProductVariant>[]);
    _syncPreviewVisibleProducts();
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewArchiveProduct(String productId, bool isActive) {
    final index = _adminProducts.indexWhere((product) => product.id == productId);
    if (index < 0) {
      _setError(const ApiException('Product not found.'));
      notifyListeners();
      return false;
    }

    _adminProducts[index] = _adminProducts[index].copyWith(isActive: isActive);
    _syncPreviewVisibleProducts();
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewCreateVariant({
    required String productId,
    required String label,
    required double price,
    required int stockQuantity,
    required bool isActive,
  }) {
    if (findProduct(productId) == null) {
      _setError(const ApiException('Product not found.'));
      notifyListeners();
      return false;
    }

    if (!isActive) {
      _clearError();
      notifyListeners();
      return true;
    }

    final variants = List<ProductVariant>.from(_variantCache[productId] ?? const <ProductVariant>[]);
    variants.insert(
      0,
      ProductVariant(
        id: 'preview-variant-${DateTime.now().microsecondsSinceEpoch}',
        productId: productId,
        label: label.trim(),
        price: price,
        stockQuantity: stockQuantity,
        isActive: true,
      ),
    );
    _variantCache[productId] = variants;
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewUpdateVariant({
    required String productId,
    required String variantId,
    required String label,
    required double price,
    required int stockQuantity,
    required bool isActive,
  }) {
    final variants = List<ProductVariant>.from(_variantCache[productId] ?? const <ProductVariant>[]);
    final index = variants.indexWhere((variant) => variant.id == variantId);
    if (index < 0) {
      _setError(const ApiException('Variant not found.'));
      notifyListeners();
      return false;
    }

    if (!isActive) {
      variants.removeAt(index);
    } else {
      variants[index] = variants[index].copyWith(
        label: label.trim(),
        price: price,
        stockQuantity: stockQuantity,
        isActive: true,
      );
    }

    _variantCache[productId] = variants;
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewArchiveVariant({
    required String productId,
    required String variantId,
  }) {
    final variants = List<ProductVariant>.from(_variantCache[productId] ?? const <ProductVariant>[])
      ..removeWhere((variant) => variant.id == variantId);
    _variantCache[productId] = variants;
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewAddComboItem({
    required String comboProductId,
    required String componentProductId,
    required int quantity,
  }) {
    final combo = findProduct(comboProductId);
    final component = findProduct(componentProductId);

    if (combo == null || !combo.isCombo) {
      _setError(const ApiException('Select a combo product to manage components.'));
      notifyListeners();
      return false;
    }
    if (component == null || !component.isActive) {
      _setError(const ApiException('Component product not found.'));
      notifyListeners();
      return false;
    }
    if (comboProductId == componentProductId) {
      _setError(const ApiException('A combo cannot contain itself.'));
      notifyListeners();
      return false;
    }

    final items = List<ComboItem>.from(_comboItemCache[comboProductId] ?? const <ComboItem>[]);
    final alreadyExists = items.any((item) => item.componentProductId == componentProductId);
    if (alreadyExists) {
      _setError(const ApiException('Component already in combo.'));
      notifyListeners();
      return false;
    }

    items.add(
      ComboItem(
        id: 'preview-combo-${DateTime.now().microsecondsSinceEpoch}',
        comboProductId: comboProductId,
        componentProductId: componentProductId,
        quantity: quantity,
        componentName: component.name,
        componentPrice: component.price,
        componentImageUrl: component.imageUrl,
      ),
    );
    _comboItemCache[comboProductId] = items;
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewUpdateComboItem({
    required String comboProductId,
    required String itemId,
    required int quantity,
  }) {
    final items = List<ComboItem>.from(_comboItemCache[comboProductId] ?? const <ComboItem>[]);
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0) {
      _setError(const ApiException('Combo item not found.'));
      notifyListeners();
      return false;
    }

    items[index] = items[index].copyWith(quantity: quantity);
    _comboItemCache[comboProductId] = items;
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewRemoveComboItem({
    required String comboProductId,
    required String itemId,
  }) {
    final items = List<ComboItem>.from(_comboItemCache[comboProductId] ?? const <ComboItem>[])
      ..removeWhere((item) => item.id == itemId);
    _comboItemCache[comboProductId] = items;
    _clearError();
    notifyListeners();
    return true;
  }

  bool _previewUpdateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      _setError(const ApiException('Order not found.'));
      notifyListeners();
      return false;
    }

    _orders[index] = _orders[index].copyWith(status: newStatus);
    _clearError();
    notifyListeners();
    return true;
  }

  String? _statusSuffix(String newStatus) {
    switch (newStatus) {
      case 'PACKED':
        return 'pack';
      case 'SHIPPED':
        return 'ship';
      case 'DELIVERED':
        return 'deliver';
      case 'CANCELLED':
        return 'cancel';
      default:
        return null;
    }
  }

  void _setError(Object error) {
    if (error is ApiException) {
      _errorMessage = error.message;
      return;
    }

    final raw = error.toString();
    _errorMessage = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }

  void _clearError() {
    _errorMessage = null;
  }
}
