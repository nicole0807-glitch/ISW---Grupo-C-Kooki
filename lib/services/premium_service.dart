import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumPaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  const PremiumPaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
  });
}

class PremiumService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _premiumKey = 'premium_is_active';
  static const _premiumUntilKey = 'premium_until_iso';
  static const _premiumAutoRenewKey = 'premium_auto_renew';
  static const bool _forceDemoMode = true;
  static const bool _allowDemoFallback = true;

  Future<bool> isPremiumActive() async {
    final prefs = await SharedPreferences.getInstance();
    bool isActive = prefs.getBool(_premiumKey) ?? false;
    String? untilIso = prefs.getString(_premiumUntilKey);

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final profile = await _supabase
            .from('Profile')
            .select('is_premium, premium_until')
            .eq('user_id', user.id)
            .maybeSingle();

        if (profile != null) {
          final dbIsActive = profile['is_premium'] == true;
          final dbUntilIso = profile['premium_until'] as String?;

          if (dbIsActive && dbUntilIso != null) {
            final until = DateTime.tryParse(dbUntilIso);
            if (until != null && until.isAfter(DateTime.now())) {
              // Sincronizar localmente si es diferente
              if (!isActive || untilIso != dbUntilIso) {
                await prefs.setBool(_premiumKey, true);
                await prefs.setString(_premiumUntilKey, dbUntilIso);
                isActive = true;
                untilIso = dbUntilIso;
              }
            }
          }
        }
      } catch (e) {
        print('Error al verificar premium en Supabase: $e');
      }
    }

    if (!isActive || untilIso == null) {
      return false;
    }

    final until = DateTime.tryParse(untilIso);
    if (until == null || until.isBefore(DateTime.now())) {
      await clearPremiumState();
      return false;
    }

    return true;
  }

  Future<DateTime?> premiumUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final untilIso = prefs.getString(_premiumUntilKey);
    return untilIso == null ? null : DateTime.tryParse(untilIso);
  }

  Future<bool> isAutoRenewEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumAutoRenewKey) ?? false;
  }

  Future<void> setAutoRenewEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumAutoRenewKey, enabled);

    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('Profile').update({
        'premium_auto_renew': enabled,
      }).eq('user_id', user.id);
    } catch (_) {
      // No bloquea si aún no existe columna en BD.
    }
  }

  Future<PremiumPaymentResult> payMonthlyMembership() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const PremiumPaymentResult(
        success: false,
        message: 'Debes iniciar sesion para suscribirte.',
      );
    }

    if (_forceDemoMode) {
      await _activatePremiumNow();
      await _sendReceipt(
        user.email ?? '',
        'DEMO-${DateTime.now().millisecondsSinceEpoch}',
      );
      return const PremiumPaymentResult(
        success: true,
        message: 'Pago simulado (demo). Premium activado correctamente.',
      );
    }

    try {
      // Conexión segura: Supabase Functions usa HTTPS para invocar la pasarela.
      final response = await _supabase.functions.invoke(
        'premium-checkout',
        body: {
          'plan': 'monthly_premium',
          'amount': 9.99,
          'currency': 'USD',
          'user_id': user.id,
          'email': user.email,
        },
      );

      final data = (response.data is Map<String, dynamic>)
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final success = data['success'] == true;
      final transactionId = data['transaction_id']?.toString();

      if (!success) {
        return PremiumPaymentResult(
          success: false,
          message: data['message']?.toString() ?? 'La transaccion fue rechazada.',
        );
      }

      await _activatePremiumNow();
      await _sendReceipt(user.email ?? '', transactionId ?? 'N/A');

      return PremiumPaymentResult(
        success: true,
        message: 'Pago procesado correctamente. Premium activo.',
        transactionId: transactionId,
      );
    } on FunctionException catch (e) {
      final errorText = _edgeFunctionErrorText(e);
      final functionMissing = _isMissingCheckoutFunction(errorText);

      if (_allowDemoFallback && functionMissing) {
        await _activatePremiumNow();
        await _sendReceipt(user.email ?? '', 'DEMO-${DateTime.now().millisecondsSinceEpoch}');
        return PremiumPaymentResult(
          success: true,
          message:
              'Pasarela no configurada aun. Se activo Premium en modo demo para pruebas.',
        );
      }

      return PremiumPaymentResult(
        success: false,
        message: errorText.isEmpty
            ? 'No se pudo procesar el pago en este momento.'
            : 'Error de pago: $errorText',
      );
    } catch (e) {
      return PremiumPaymentResult(
        success: false,
        message: 'No se pudo procesar el pago en este momento: $e',
      );
    }
  }

  String _edgeFunctionErrorText(FunctionException e) {
    final details = e.details;
    if (details is Map && details['message'] != null) {
      return details['message'].toString();
    }
    if (details != null) {
      return details.toString();
    }
    return e.reasonPhrase ?? '';
  }

  bool _isMissingCheckoutFunction(String errorText) {
    final t = errorText.toLowerCase();
    return t.contains('not found') ||
        t.contains('404') ||
        t.contains('does not exist') ||
        t.contains('premium-checkout');
  }

  Future<void> _activatePremiumNow() async {
    final currentUntil = await premiumUntil();
    final base = (currentUntil != null && currentUntil.isAfter(DateTime.now()))
        ? currentUntil
        : DateTime.now();
    final until = base.add(const Duration(days: 30));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
    await prefs.setString(_premiumUntilKey, until.toIso8601String());

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    // Persistencia remota opcional (si las columnas existen).
    try {
      await _supabase.from('Profile').update({
        'is_premium': true,
        'premium_until': until.toIso8601String(),
      }).eq('user_id', user.id);
    } catch (_) {
      // No bloquea el flujo si el esquema aún no tiene estas columnas.
    }
  }

  Future<void> _sendReceipt(String email, String transactionId) async {
    if (email.isEmpty) {
      return;
    }

    try {
      await _supabase.functions.invoke(
        'send-payment-receipt',
        body: {
          'email': email,
          'transaction_id': transactionId,
          'plan': 'Premium Mensual',
          'amount': 9.99,
          'currency': 'USD',
          'paid_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      // El pago ya fue exitoso; no desactivar premium por fallo de email.
    }
  }

  Future<void> clearPremiumState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_premiumKey);
    await prefs.remove(_premiumUntilKey);
    await prefs.remove(_premiumAutoRenewKey);
  }
}
