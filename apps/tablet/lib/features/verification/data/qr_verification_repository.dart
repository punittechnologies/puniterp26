import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';

class QrVerificationRepository {
  const QrVerificationRepository({this.apiClient});

  final ApiClient? apiClient;

  Future<String> createPublicUrl({
    required String sourceTransactionId,
    required String productId,
    String? variantId,
    required String productName,
    String? variantName,
    String? variantCode,
    required String serialNumber,
    required String barcodeValue,
    required num grossWeight,
    required num tareWeight,
    required num netWeight,
    num? pieceQuantity,
    required String unit,
    required DateTime printedAt,
    required Map<String, dynamic> dynamicValues,
    required Map<String, dynamic> productRaw,
  }) async {
    final client = apiClient ?? await ApiSession.client();
    if (client == null) {
      throw StateError(
        'Internet login is required to create a secure QR verification page.',
      );
    }
    final Response<dynamic> response;
    try {
      response = await client.post(
        '/qr/verifications',
        data: {
          'source_transaction_id': sourceTransactionId,
          'product_id': productId,
          'variant_id': variantId,
          'product_name': productName,
          'variant_name': variantName,
          'variant_code': variantCode,
          'serial_number': serialNumber,
          'barcode_value': barcodeValue,
          'gross_weight': grossWeight,
          'tare_weight': tareWeight,
          'net_weight': netWeight,
          'piece_quantity': pieceQuantity,
          'unit': unit,
          'printed_at': printedAt.toIso8601String(),
          'dynamic_values': dynamicValues,
          'product_raw': productRaw,
        },
        idempotencyKey: 'qr_$sourceTransactionId',
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final errors = data is Map ? data['errors'] : null;
      final qrErrors = errors is Map ? errors['qr'] : null;
      final message = qrErrors is List && qrErrors.isNotEmpty
          ? qrErrors.first.toString()
          : data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Secure QR verification is unavailable. Check internet and QR Page Design settings.';
      throw StateError(message);
    }
    final data = response.data;
    if (data is! Map || data['publicUrl']?.toString().trim().isEmpty != false) {
      throw StateError('The server did not return a QR verification URL.');
    }

    return data['publicUrl'].toString();
  }
}
