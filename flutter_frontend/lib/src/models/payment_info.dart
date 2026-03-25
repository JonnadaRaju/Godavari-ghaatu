import 'dart:convert';
import 'dart:typed_data';

class PaymentInfo {
  const PaymentInfo({
    required this.upiId,
    required this.upiName,
    required this.amount,
    required this.orderCode,
    required this.qrCodeDataUrl,
    required this.instructions,
  });

  final String upiId;
  final String upiName;
  final double amount;
  final String orderCode;
  final String qrCodeDataUrl;
  final List<String> instructions;

  Uint8List? get qrBytes {
    if (!qrCodeDataUrl.contains(',')) {
      return null;
    }
    final encoded = qrCodeDataUrl.split(',').last;
    return base64Decode(encoded);
  }

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    final instructions = (json['instructions'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .toList();

    return PaymentInfo(
      upiId: (json['upi_id'] as String?) ?? '',
      upiName: (json['upi_name'] as String?) ?? '',
      amount: _asDouble(json['amount']),
      orderCode: (json['order_id'] as String?) ?? '',
      qrCodeDataUrl: (json['qr_code'] as String?) ?? '',
      instructions: instructions,
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
