import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temple_app/services/ad_helper.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _disposed = false;

  void loadAd() {
    if (_disposed || kIsWeb || !AdHelper.isSupported) return;
    unawaited(_loadWhenConsentResolved());
  }

  Future<void> _loadWhenConsentResolved() async {
    await AdHelper.ready;
    if (_disposed || !AdHelper.shouldRequestAds) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdHelper.adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
          _isAdReady = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _isAdReady = false;
        },
      ),
    );
  }

  bool showAdIfAvailable() {
    if (kIsWeb) return false;
    if (_isAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _isAdReady = false;
      return true;
    }
    return false;
  }

  void dispose() {
    _disposed = true;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
