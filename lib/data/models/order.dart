import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_labels.dart';
import 'json.dart';

/// Pesanan laundry dari `/api/orders`.
///
/// Response daftar/detail sudah menggabungkan nama layanan dan nama pemesan,
/// sehingga aplikasi tidak perlu meminta dua kali.
class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.estimatedWeight,
    required this.pricePerKg,
    required this.status,
    this.customerName,
    this.customerEmail,
    this.serviceName,
    this.serviceDuration,
    this.actualWeight,
    this.totalPrice,
    this.photoUrl,
    this.createdAt,
    this.paymentMethod,
    this.paymentStatus,
    this.paidAt,
  });

  final int id;
  final int userId;
  final int serviceId;
  final String? customerName;
  final String? customerEmail;
  final String? serviceName;
  final String? serviceDuration;
  final double estimatedWeight;
  final double? actualWeight;
  final double pricePerKg;
  final double? totalPrice;
  final String status;

  /// Path relatif dari backend (mis. `/uploads/xxx.jpg`), sudah diubah
  /// menjadi URL lengkap agar bisa langsung dimuat.
  final String? photoUrl;
  final DateTime? createdAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime? paidAt;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: Json.toInt(json['id']) ?? 0,
      userId: Json.toInt(json['user_id']) ?? 0,
      serviceId: Json.toInt(json['service_id']) ?? 0,
      customerName: Json.toText(json['customer_name']),
      customerEmail: Json.toText(json['customer_email']),
      serviceName: Json.toText(json['service_name']),
      serviceDuration: Json.toText(json['service_duration']),
      estimatedWeight: Json.toDouble(json['estimated_weight']) ?? 0,
      actualWeight: Json.toDouble(json['actual_weight']),
      pricePerKg: Json.toDouble(json['price_per_kg']) ?? 0,
      totalPrice: Json.toDouble(json['total_price']),
      status: Json.text(json['status'], fallback: OrderLabels.pendingConfirmation),
      photoUrl: ApiConfig.resolveUrl(Json.toText(json['photo_url'])),
      createdAt: Json.toDate(json['created_at']),
      paymentMethod: Json.toText(json['payment_method']),
      paymentStatus: Json.toText(json['payment_status']),
      paidAt: Json.toDate(json['paid_at']),
    );
  }

  String get nomor => Formats.nomorPesanan(id);

  String get namaLayanan => serviceName?.trim().isNotEmpty == true
      ? serviceName!.trim()
      : 'Layanan #$serviceId';

  String get namaCustomer =>
      customerName?.trim().isNotEmpty == true ? customerName!.trim() : 'Pengguna #$userId';

  bool get sudahFinal => OrderLabels.sudahFinal(status);

  bool get sudahLunas => paymentStatus == 'PAID';

  bool get sudahAdaBeratAsli => actualWeight != null;

  /// Total yang ditampilkan: harga akhir dari server bila sudah ada,
  /// jika belum, perkiraan dari estimasi berat dikali harga per kg.
  /// Nilai perkiraan diberi keterangan "perkiraan" di layar.
  double get totalPerkiraan => totalPrice ?? (estimatedWeight * pricePerKg);

  bool get totalSudahFinal => totalPrice != null;

  @override
  String toString() => 'Order(#$id, $status)';
}

@immutable
class OrderPage {
  const OrderPage({required this.items, this.jumlah});

  final List<Order> items;
  final int? jumlah;
}
