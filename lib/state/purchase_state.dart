import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bu sınıf tamamen satın alma işlemlerinden sorumludur.
/// AppState, Premium durumunu buradan öğrenir.
class PurchaseState extends ChangeNotifier {
  bool premiumActive = false;
  String? planId;
  DateTime? expiresAt;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  PurchaseState();

  /// ⭐ initialize → storage yükle + listener başlat
  Future<void> initialize() async {
    await loadFromStorage();
    _listenToPurchases();
  }

  /// Satın alma stream'ini dinler
  void _listenToPurchases() {
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) {
          _activatePremium(
            plan: p.productID,
            expires: DateTime.now().add(const Duration(days: 365)),
          );

          InAppPurchase.instance.completePurchase(p);

          debugPrint("💎 PurchaseState: Premium activated → ${p.productID}");
        }

        if (p.status == PurchaseStatus.error) {
          debugPrint("❌ Purchase error: ${p.error}");
        }
      }
    });
  }

  /// Premium’u aktif eder
  void _activatePremium({
    required String plan,
    required DateTime expires,
  }) {
    premiumActive = true;
    planId = plan;
    expiresAt = expires;

    saveToStorage(); // ⭐ premium kaydedilsin
    notifyListeners();
  }

  /// Storage → state güncelle
  void updateFromStorage({
    required bool active,
    String? plan,
    DateTime? expires,
  }) {
    premiumActive = active;
    planId = plan;
    expiresAt = expires;
    notifyListeners();
  }

  bool get isPremiumValid {
    if (!premiumActive) return false;
    if (expiresAt == null) return true;
    return expiresAt!.isAfter(DateTime.now());
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("premiumActive", premiumActive);
    prefs.setString("premiumPlanId", planId ?? "");
    prefs.setString("premiumExpiresAt", expiresAt?.toIso8601String() ?? "");
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final active = prefs.getBool("premiumActive") ?? false;
    final plan = prefs.getString("premiumPlanId");
    final expiresRaw = prefs.getString("premiumExpiresAt");

    DateTime? expires;
    if (expiresRaw != null && expiresRaw.isNotEmpty) {
      expires = DateTime.tryParse(expiresRaw);
    }

    updateFromStorage(active: active, plan: plan, expires: expires);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
