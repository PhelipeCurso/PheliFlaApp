import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Serviço simples para gerenciar Interstitial Ads (tela cheia).
class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  InterstitialAd? _interstitial;
  bool _isLoading = false;

  /// ID de teste do Interstitial (use seu ID real em produção).
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/8691691433';

  /// Inicializa o SDK (idempotente).
  Future<InitializationStatus> initialize() async {
    return await MobileAds.instance.initialize();
  }

  /// Carrega um interstitial. Se [showOnLoad] for true ele exibirá assim que carregado.
  /// Se [isPlusUser] for true, não carrega nenhum anúncio.
  void loadInterstitial({
    String? adUnitId,
    bool showOnLoad = false,
    bool isPlusUser = false,
  }) {
    // Usuários Plus não veem anúncios
    if (isPlusUser) {
      debugPrint('✓ Usuário Plus — anúncio não será exibido.');
      return;
    }

    if (_interstitial != null || _isLoading) return;
    _isLoading = true;

    final unitId = adUnitId ?? _testAdUnitId;

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitial = null;
            },
          );
          if (showOnLoad) {
            tryShowInterstitial();
          }
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Tenta exibir o interstitial carregado. Retorna true se a exibição foi iniciada.
  bool tryShowInterstitial() {
    if (_interstitial == null) return false;
    try {
      _interstitial!.show();
      return true;
    } catch (e) {
      debugPrint('Erro ao mostrar interstitial: $e');
      return false;
    }
  }

  /// Descartar qualquer interstitial carregado.
  void disposeInterstitial() {
    _interstitial?.dispose();
    _interstitial = null;
    _isLoading = false;
  }
}
