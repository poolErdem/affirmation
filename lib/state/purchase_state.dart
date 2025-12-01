import 'dart:async';

import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseState {
  final AppState appState;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Gerçek constructor (production)
  PurchaseState(this.appState);

  /// Ürün listesi
  final Map<String, ProductDetails> products = {};

  /// Listener bir kere kurulsun diye flag
  bool _listenerInitialized = false;
  bool _isInitialized = false;

  //────────────────────────────────────────
  // INITIALIZE (AppState.initialize()'dan çağrılacak)
  //────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) {
      print("⚠️ PurchaseState zaten initialize edilmiş");
      return;
    }

    try {
      if (!_listenerInitialized) {
        _initPurchaseListener();
        _listenerInitialized = true;
      }

      await initStoreAvailability();
      _isInitialized = true;
      print("✅ PurchaseState initialized successfully");
    } catch (e) {
      print("❌ PurchaseState initialization error: $e");
    }
  }

  bool storeAvailable = false;

  Future<void> initStoreAvailability() async {
    try {
      storeAvailable = await InAppPurchase.instance.isAvailable();
      print("🛒 Store available: $storeAvailable");
    } catch (e) {
      print("❌ Store availability check failed: $e");
      storeAvailable = false;
    }
  }

  //────────────────────────────────────────
  // STORE ÜRÜNLERİNİ ÇEK (Monthly - Yearly - Lifetime)
  //────────────────────────────────────────
  Future<void> fetchProducts() async {
    if (!_isInitialized) {
      print(
          "⚠️ PurchaseState henüz initialize edilmedi, fetchProducts atlanıyor");
      return;
    }

    if (!storeAvailable) {
      print("⚠️ Store kullanılamıyor, fetchProducts atlanıyor");
      return;
    }

    const ids = {Constants.monthly, Constants.yearly, Constants.lifetime};

    try {
      final response = await InAppPurchase.instance.queryProductDetails(ids);

      if (response.error != null) {
        print("❌ Product fetch error: ${response.error}");
        return;
      }

      products.clear();
      for (final p in response.productDetails) {
        products[p.id] = p;
      }

      print("🛒 Loaded products: ${products.keys.toList()}");
    } catch (e) {
      print("❌ fetchProducts exception: $e");
    }
  }

  //────────────────────────────────────────
  // LISTENER (TEK SEFER BAĞLANIR)
  //────────────────────────────────────────
  void _initPurchaseListener() {
    try {
      final purchaseUpdates = InAppPurchase.instance.purchaseStream;

      _subscription = purchaseUpdates.listen(
        _handlePurchaseUpdates,
        onError: (e) => print("❌ Purchase stream error: $e"),
        onDone: () => print("✅ Purchase stream closed"),
        cancelOnError: false,
      );

      print("🎧 Purchase listener aktif (PurchaseState)");
    } catch (e) {
      print("❌ Purchase listener başlatma hatası: $e");
    }
  }

  //────────────────────────────────────────
  // DISPOSE
  //────────────────────────────────────────
  Future<void> dispose() async {
    print("🧹 Disposing PurchaseState...");
    try {
      await _subscription?.cancel();
      _subscription = null;
      _listenerInitialized = false;
      _isInitialized = false;
      products.clear();
      print("✅ PurchaseState disposed");
    } catch (e) {
      print("❌ Dispose error: $e");
    }
  }

  //────────────────────────────────────────
  // PURCHASE HANDLER
  //────────────────────────────────────────
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      print(
          "💰 Purchase update: ${purchase.productID} status=${purchase.status}");

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _activatePlan(purchase.productID);
      }

      if (purchase.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  void _activatePlan(String productId) {
    if (productId == Constants.monthly) {
      appState.updatePremium(
        active: true,
        plan: PremiumPlan.monthly,
        expiry: DateTime.now().add(const Duration(days: 30)),
      );
    }

    if (productId == Constants.yearly) {
      appState.updatePremium(
        active: true,
        plan: PremiumPlan.yearly,
        expiry: DateTime.now().add(const Duration(days: 365)),
      );
    }

    if (productId == Constants.lifetime) {
      appState.updatePremium(
        active: true,
        plan: PremiumPlan.lifetime,
        expiry: null,
      );
    }
  }

  //────────────────────────────────────────
  // RESTORE
  //────────────────────────────────────────
  Future<void> restorePurchases() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      print("🍏 iOS restorePurchases() çağrıldı");
      try {
        await InAppPurchase.instance.restorePurchases();
      } catch (e) {
        print("❌ Restore purchases error: $e");
      }
    } else {
      print("🤖 Android → restorePurchases() kullanılmaz");
    }
  }
}
