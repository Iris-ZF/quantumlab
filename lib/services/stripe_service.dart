import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'firebase_service.dart';

/// Stripe payment service for web platform.
/// On mobile, this delegates to native IAP (future RevenueCat integration).
/// On web, opens Stripe Checkout.
class StripeService {
  static StripeService? _instance;
  static StripeService get instance => _instance ??= StripeService._();
  StripeService._();

  /// Your Stripe payment link for QuantumLab Pro.
  /// Replace with actual Stripe payment link or Checkout URL.
  static const _stripeLifetimeUrl = 'https://buy.stripe.com/YOUR_LIFETIME_LINK';
  static const _stripeMonthlyUrl = 'https://buy.stripe.com/YOUR_MONTHLY_LINK';

  bool get isWeb => kIsWeb;

  /// Initiate purchase flow.
  /// On web: opens Stripe Checkout in a new tab.
  /// On mobile: would use RevenueCat (placeholder).
  Future<bool> purchaseLifetime() async {
    if (kIsWeb) {
      return _openStripeCheckout(_stripeLifetimeUrl);
    }
    // Mobile: placeholder for RevenueCat
    return false;
  }

  Future<bool> purchaseMonthly() async {
    if (kIsWeb) {
      return _openStripeCheckout(_stripeMonthlyUrl);
    }
    return false;
  }

  Future<bool> _openStripeCheckout(String url) async {
    final userId = FirebaseService.instance.userId;
    // Append client_reference_id so Stripe webhook can match to user
    final checkoutUrl = '$url?client_reference_id=${userId ?? "anonymous"}';
    try {
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Verify purchase via Firebase (Stripe webhook writes to Firestore).
  Future<bool> verifyPurchase() async {
    return FirebaseService.instance.getProStatus();
  }
}
