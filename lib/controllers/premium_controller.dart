import 'package:flutter/foundation.dart';

import '../services/premium_service.dart';

class PremiumController extends ChangeNotifier {
  final PremiumService _service = PremiumService();

  bool _isLoading = false;
  bool _isPremium = false;
  DateTime? _premiumUntil;
  String? _lastMessage;

  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  DateTime? get premiumUntil => _premiumUntil;
  String? get lastMessage => _lastMessage;

  Future<void> loadStatus() async {
    _isPremium = await _service.isPremiumActive();
    _premiumUntil = await _service.premiumUntil();
    notifyListeners();
  }

  Future<bool> subscribeMonthly() async {
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    final result = await _service.payMonthlyMembership();

    _isLoading = false;
    _lastMessage = result.message;

    if (result.success) {
      _isPremium = true;
      _premiumUntil = await _service.premiumUntil();
    }

    notifyListeners();
    return result.success;
  }
}
