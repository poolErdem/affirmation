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

  PurchaseState(this.appState);

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

      if (storeAvailable) {
        await fetchProducts();
      }

      _isInitialized = true;
      print("✅ PurchaseState initialized");
    } catch (e) {
      print("❌ PurchaseState initialize error: $e");
    }
  }

  //────────────────────────────────────────
  // PRICE LABELS
  //────────────────────────────────────────

  String get monthlyPriceLabel => isTurkey ? "₺29,99 / ay" : "€2.99 / month";

  String get yearlyPriceLabel => isTurkey ? "₺199,99 / yıl" : "€29.99 / year";

  String get lifeTimePriceLabel =>
      isTurkey ? "₺399,99 / ömür boyu" : "€29.99 / lifetime";

  bool get productsReady => products.isNotEmpty && storeAvailable;

  //────────────────────────────────────────
  // BUY PLAN — SAFE ENTRY POINT
  //────────────────────────────────────────
  Future<void> buyPlan(String id) async {
    try {
      if (!storeAvailable) {
        debugPrint("❌ Store not available");
        return;
      }

      const validPlans = [
        Constants.monthly,
        Constants.yearly,
        Constants.lifetime,
      ];

      if (!validPlans.contains(id)) {
        debugPrint("❌ Invalid plan ID: $id");
        return;
      }

      final product = products[id];
      if (product == null) {
        debugPrint("❌ Product not loaded: $id");
        return;
      }

      final param = PurchaseParam(productDetails: product);

      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);

      debugPrint("✅ Purchase request sent → $id");
    } catch (e) {
      debugPrint("❌ Purchase error: $e");
    }
  }

  //────────────────────────────────────────
  // STORE AVAILABILITY
  //────────────────────────────────────────
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
    if (!storeAvailable) return;

    const ids = {Constants.monthly, Constants.yearly, Constants.lifetime};

    try {
      final response = await InAppPurchase.instance.queryProductDetails(ids);

      if (response.error != null) {
        print("❌ Product fetch error: ${response.error}");
        return;
      }

      products
        ..clear()
        ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));

      print("🛒 Products loaded: ${products.keys}");
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  //────────────────────────────────────────
  // HANDLE PURCHASE UPDATES
  //────────────────────────────────────────
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      print("💰 Update: ${purchase.productID} → ${purchase.status}");

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final verified = _verifyPurchase(purchase);

        if (verified) {
          _activatePlan(purchase.productID);
        }
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  //────────────────────────────────────────
  // VERIFY PURCHASE (client-side minimum)
  //────────────────────────────────────────
  bool _verifyPurchase(PurchaseDetails p) {
    if (p.status == PurchaseStatus.purchased) return true;
    if (p.status == PurchaseStatus.restored) return true;
    return false;
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
    print("⭐ Updating premium → $plan / Active=$active");

    final updated = appState.preferences.copyWith(
      premiumActive: active,
      premiumPlanId: plan,
      premiumExpiresAt: expiry,
    );

    appState.updatePreferences(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("premiumActive", active);
    await prefs.setString("premiumPlanId", plan.name);
    await prefs.setString(
      "premiumExpiresAt",
      expiry?.toIso8601String() ?? "",
    );

    appState.clearAffirmationCache();
    notifyListeners();
  }

  //────────────────────────────────────────
  // RESTORE PURCHASES
  //────────────────────────────────────────
  Future<void> restorePurchases() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      print("🍏 iOS restorePurchases()");
      try {
        await InAppPurchase.instance.restorePurchases();
      } catch (e) {
        print("❌ Restore error: $e");
      }
    } else {
      print("🤖 Android: restorePurchases() opsiyonel");
    }
  }

  //────────────────────────────────────────
  // LOCALE CHECK
  //────────────────────────────────────────
  bool get isTurkey {
    final locale = Platform.localeName.toLowerCase();
    return locale.endsWith("tr");
  }
}
