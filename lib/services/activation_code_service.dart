import 'dart:convert';
import 'package:http/http.dart' as http;

class ActivationCodeResult {
  final bool success;
  final String? message;
  final String? planType;
  final int? durationMonths;

  ActivationCodeResult({
    required this.success,
    this.message,
    this.planType,
    this.durationMonths,
  });
}

class ActivationCodeService {
  static const String backendUrl = 'https://backend-fedapay-gestboutique.onrender.com';

  static Future<ActivationCodeResult> validateCode({
    required String code,
    required String storeId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/activation-codes/validate'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'code': code.trim().toUpperCase(),
              'store_id': storeId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return ActivationCodeResult(
          success: true,
          message: data['message']?.toString(),
          planType: data['plan_type']?.toString(),
          durationMonths: data['duration_months'] is int
              ? data['duration_months']
              : int.tryParse(data['duration_months']?.toString() ?? ''),
        );
      }

      return ActivationCodeResult(
        success: false,
        message: data['message']?.toString() ?? 'Code invalide',
      );
    } catch (e) {
      return ActivationCodeResult(
        success: false,
        message: 'Erreur de connexion au serveur',
      );
    }
  }
}
