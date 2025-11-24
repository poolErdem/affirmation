import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 🔥 Her 5 affirmation'dan sonra gösterilecek reklam kartı
class InlineAdCard extends StatefulWidget {
  const InlineAdCard({super.key});

  @override
  State<InlineAdCard> createState() => _InlineAdCardState();
}

class _InlineAdCardState extends State<InlineAdCard> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-3940256099942544/6300978111', // TEST ID - Gerçek ID ile değiştirin
      size: AdSize.mediumRectangle, // 🔥 300x250 - affirmation boyutunda
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
          print('✅ Inline reklam yüklendi');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Inline reklam yükleme hatası: $error');
          ad.dispose();
          if (mounted) {
            setState(() => _isLoaded = false);
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Reklam" etiketi
            Text(
              'Advertisement',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 12),

            // Reklam widget'ı
            _isLoaded && _bannerAd != null
                ? SizedBox(
                    height: _bannerAd!.size.height.toDouble(),
                    width: _bannerAd!.size.width.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  )
                : SizedBox(
                    height: 250,
                    width: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),

            const SizedBox(height: 8),

            // Yukarı kaydır ipucu
            Text(
              'Swipe up to continue',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
