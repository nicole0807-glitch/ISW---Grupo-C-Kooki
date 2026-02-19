import 'package:flutter/foundation.dart';

import '../services/premium_service.dart';

class PremiumController extends ChangeNotifier {
  final PremiumService _service = PremiumService();

  bool _isLoading = false;
  bool _isPremium = false;
  DateTime? _premiumUntil;
  bool _autoRenewEnabled = false;
  String? _lastMessage;

  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  DateTime? get premiumUntil => _premiumUntil;
  bool get autoRenewEnabled => _autoRenewEnabled;
  String? get lastMessage => _lastMessage;
  int get daysRemaining {
    if (!_isPremium || _premiumUntil == null) return 0;
    final now = DateTime.now();
    final diff = _premiumUntil!.difference(now);
    if (diff.isNegative) return 0;
    return diff.inHours <= 24 ? 1 : (diff.inDays + 1);
  }

  Future<void> loadStatus() async {
    _isPremium = await _service.isPremiumActive();
    _premiumUntil = await _service.premiumUntil();
    _autoRenewEnabled = await _service.isAutoRenewEnabled();
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
      _autoRenewEnabled = await _service.isAutoRenewEnabled();
    }

    notifyListeners();
    return result.success;
  }

  Future<void> setAutoRenew(bool enabled) async {
    _autoRenewEnabled = enabled;
    notifyListeners();
    await _service.setAutoRenewEnabled(enabled);
  }
}
