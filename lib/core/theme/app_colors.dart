import 'package:flutter/material.dart';

/// Palet RENOVA. Dipakai hemat: putih mendominasi layar, cyan hanya untuk
/// tindakan utama dan elemen aktif, coral hanya untuk hal yang perlu
/// perhatian (mis. pesanan menunggu konfirmasi atau pembayaran belum lunas).
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF00ACC1); // Deep Cyan
  static const Color primarySoft = Color(0xFFE0F7FA); // Ice Cyan
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color surface = Color(0xFFF8FAFC); // Cool Off-White
  static const Color accent = Color(0xFFFF7043); // Coral Orange
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate
  static const Color textSecondary = Color(0xFF64748B); // Muted Slate
  static const Color border = Color(0xFFE2E8F0); // Light Slate

  /// Warna status. Hanya tiga nada, supaya status tidak menjadi pelangi:
  /// netral (abu), perhatian (coral), dan selesai/aktif (cyan).
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color accentSoft = Color(0xFFFFF3EE);
  static const Color neutralSoft = Color(0xFFF1F5F9);
}
