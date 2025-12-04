import 'dart:async';
import 'dart:io';

import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseState extends ChangeNotifier {
  final AppState appState;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Constructor
  PurchaseState(this.appState);

  /// Store ürünleri
  final Map<String, ProductDetails> products = {};

  bool _listenerInitialized = false;
  bool _isInitialized = false;
  bool storeAvailable = false;

  //────────────────────────────────────────
  // INITIALIZE
  //────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) {
      print("⚠️ PurchaseState zaten initialize edildi");
      return;
    }

    try {
      if (!_listenerInitialized) {
        _initPurchaseListener();
        _listenerInitialized = true;
      }

      await initStoreAvailability();
      _isInitialized = true;

      print("✅ PurchaseState initialized");
    } catch (e) {
      print("❌ PurchaseState initialize error: $e");
    }
  }

  String get monthlyPriceLabel {
    return isTurkey ? "₺29,99 / ay" : "€2.99 / month";
  }

  String get yearlyPriceLabel {
    return isTurkey ? "₺199,99 / yıl" : "€29.99 / year";
  }

  String get lifeTimePriceLabel {
    return isTurkey ? "₺399,99 / ömür boyu" : "€29.99 / life time";
  }

  Future<void> initStoreAvailability() async {
    try {
      storeAvailable = await InAppPurchase.instance.isAvailable();
      print("🛒 Store available: $storeAvailable");
    } catch (e) {
      print("❌ Store availability check error: $e");
      storeAvailable = false;
    }
  }

  //────────────────────────────────────────
  // FETCH PRODUCTS
  //────────────────────────────────────────
  Future<void> fetchProducts() async {
    if (!_isInitialized) {
      print("⚠️ PurchaseState initialize edilmedi → fetchProducts atlandı");
      return;
    }

    if (!storeAvailable) {
      print("⚠️ Store kapalı → fetchProducts atlandı");
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

      print("🛒 Products loaded: ${products.keys.toList()}");
    } catch (e) {
      print("❌ fetchProducts exception: $e");
    }
  }

  //────────────────────────────────────────
  // LISTENER
  //────────────────────────────────────────
  void _initPurchaseListener() {
    try {
      final purchaseStream = InAppPurchase.instance.purchaseStream;

      _subscription = purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (e) => print("❌ Purchase stream error: $e"),
        onDone: () => print("🎧 Purchase stream closed"),
        cancelOnError: false,
      );

      print("🎧 Purchase listener aktif");
    } catch (e) {
      print("❌ Listener başlatılamadı: $e");
    }
  }

  //────────────────────────────────────────
  // DISPOSE
  //────────────────────────────────────────
  Future<void> disposeState() async {
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

  @override
  void dispose() {
    disposeState();
    super.dispose();
  }

  //────────────────────────────────────────
  // PURCHASE HANDLER
  //────────────────────────────────────────
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      print("💰 Purchase update: ${purchase.productID} → ${purchase.status}");

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _activatePlan(purchase.productID);
          break;

        default:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  //────────────────────────────────────────
  // ACTIVATE PLAN
  //────────────────────────────────────────
  void _activatePlan(String productId) {
    if (productId == Constants.monthly) {
      updatePremium(
        active: true,
        plan: PremiumPlan.monthly,
        expiry: DateTime.now().add(const Duration(days: 30)),
      );
    }

    if (productId == Constants.yearly) {
      updatePremium(
        active: true,
        plan: PremiumPlan.yearly,
        expiry: DateTime.now().add(const Duration(days: 365)),
      );
    }

    if (productId == Constants.lifetime) {
      updatePremium(
        active: true,
        plan: PremiumPlan.lifetime,
        expiry: null,
      );
    }
  }

  //────────────────────────────────────────
  // UPDATE PREMIUM
  //────────────────────────────────────────
  Future<void> updatePremium({
    required bool active,
    required PremiumPlan plan,
    required DateTime? expiry,
  }) async {
    print("⭐ Updating premium → $plan active=$active");

    // 1) Yeni preferences üret
    final updated = appState.preferences.copyWith(
      premiumActive: active,
      premiumPlanId: plan,
      premiumExpiresAt: expiry,
    );

    // 2) AppState üzerinden premium bilgilerini güncelle
    appState.updatePreferences(updated);

    // 3) Storage güncelley
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("premiumActive", active);
    await prefs.setString("premiumPlanId", plan.name);
    await prefs.setString(
      "premiumExpiresAt",
      expiry?.toIso8601String() ?? "",
    );

    appState.clearAffirmationCache();

    // 4) PurchaseState dinleyicilerini tetikle
    notifyListeners();
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
        print("❌ Restore error: $e");
      }
    } else {
      print("🤖 Android → restorePurchases() kullanılmıyor");
    }
  }

  bool get isTurkey {
    // Örnek: 'tr_TR', 'en_US'
    final locale = Platform.localeName.toLowerCase();
    return locale.endsWith("tr");
  }
}
