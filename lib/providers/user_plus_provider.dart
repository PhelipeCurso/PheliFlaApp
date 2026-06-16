import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class UserPlusProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = false;
  String? _precoPlano;

  // Getters para a sua UI ler os estados
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get precoPlano => _precoPlano;

  UserPlusProvider() {
    _initBilling();
  }

  bool? get isPlus => null;

  // Inicializa o serviço e verifica se o usuário já é premium
  Future<void> _initBilling() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Busca as ofertas configuradas no RevenueCat/Google Play
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.monthly != null) {
        _precoPlano = offerings.current!.monthly!.storeProduct.priceString;
      }

      // Verifica o status atual do usuário
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _isPremium = customerInfo.entitlements.all["plus"]?.isActive ?? false;
    } catch (e) {
      debugPrint("Erro ao inicializar faturamento: $e");
      // Fallback caso dê erro de rede ou o SDK não esteja configurado ainda
      _precoPlano = "R\$ 9,90/mês"; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Função chamada pelo botão "Assinar Agora"
  Future<bool> comprarAssinatura() async {
    _isLoading = true;
    notifyListeners();

    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current?.monthly != null) {
        // Dispara o fluxo nativo do Google Play / App Store
        CustomerInfo customerInfo = await Purchases.purchasePackage(offerings.current!.monthly!);
        
        // Verifica se o direito "plus" foi ativado com sucesso
        _isPremium = customerInfo.entitlements.all["plus"]?.isActive == true;
        return _isPremium;
      }
      return false;
    } catch (e) {
      debugPrint("Erro ou cancelamento da compra: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Caso precise atualizar manualmente o status (ex: botão de restaurar compras)
  Future<void> restaurarCompras() async {
    _isLoading = true;
    notifyListeners();
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _isPremium = customerInfo.entitlements.all["plus"]?.isActive == true;
    } catch (e) {
      debugPrint("Erro ao restaurar: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void checkPlusStatus() {}
}