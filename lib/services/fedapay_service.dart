import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class FedaPayConfig {
  static const String backendUrl = 'https://backend-fedapay-gestboutique.onrender.com';
}

class FedaPayResult {
  final bool success;
  final String? message;
  final int? transactionId;
  final String? paymentUrl;

  FedaPayResult({
    required this.success,
    this.message,
    this.transactionId,
    this.paymentUrl,
  });
}

class FedaPayService {
  static Future<FedaPayResult> createTransaction({
    required double amount,
    required String description,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
  }) async {
    try {
      final body = {
        'amount': amount.toInt(),
        'description': description,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        if (customerEmail != null && customerEmail.isNotEmpty)
          'customer_email': customerEmail,
      };

      final response = await http
          .post(
            Uri.parse('${FedaPayConfig.backendUrl}/create-payment'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return FedaPayResult(
          success: true,
          transactionId: data['transaction_id'] is int
              ? data['transaction_id']
              : int.tryParse(data['transaction_id']?.toString() ?? ''),
          paymentUrl: data['payment_url']?.toString(),
        );
      }

      return FedaPayResult(
        success: false,
        message: data['message']?.toString() ?? 'Erreur du serveur de paiement',
      );
    } on TimeoutException {
      return FedaPayResult(
        success: false,
        message:
            'La requête a expiré. Vérifiez que le serveur backend est lancé.',
      );
    } on http.ClientException catch (e) {
      return FedaPayResult(
        success: false,
        message: 'Impossible de contacter le serveur de paiement (${e.message})',
      );
    } catch (e) {
      return FedaPayResult(
        success: false,
        message: 'Erreur de connexion au serveur de paiement.',
      );
    }
  }

  static Future<bool> openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      }
    } catch (_) {}
    return false;
  }

  static Future<String?> checkPaymentStatus(int transactionId) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '${FedaPayConfig.backendUrl}/transaction-status/$transactionId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['status'] != null) {
        return data['status'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
