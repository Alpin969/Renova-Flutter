import 'package:flutter_test/flutter_test.dart';
import 'package:renova/core/utils/order_labels.dart';
import 'package:renova/data/models/order.dart';
import 'package:renova/data/models/service_item.dart';
import 'package:renova/data/models/user.dart';

void main() {
  group('Order.fromJson', () {
    // Bentuk response mengikuti SELECT_PESANAN di backend: NUMERIC dikirim
    // sebagai teks oleh driver pg, id sebagai angka.
    final json = <String, dynamic>{
      'id': 7,
      'user_id': 3,
      'customer_name': 'Budi Santoso',
      'customer_email': 'budi@mail.com',
      'service_id': 2,
      'service_name': 'Cuci Kering',
      'service_duration': '2 hari',
      'estimated_weight': '2.50',
      'actual_weight': null,
      'price_per_kg': '7000.00',
      'total_price': null,
      'status': 'PENDING_CONFIRMATION',
      'photo_url': '/uploads/abc.jpg',
      'created_at': '2026-11-12T07:05:00.000Z',
      'payment_method': 'CASH',
      'payment_status': 'UNPAID',
      'paid_at': null,
    };

    test('membaca angka yang dikirim sebagai teks', () {
      final order = Order.fromJson(json);

      expect(order.id, 7);
      expect(order.estimatedWeight, 2.5);
      expect(order.pricePerKg, 7000);
      expect(order.actualWeight, isNull);
      expect(order.totalPrice, isNull);
    });

    test('menyusun URL foto lengkap dari path relatif', () {
      final order = Order.fromJson(json);

      expect(order.photoUrl, isNotNull);
      expect(order.photoUrl, endsWith('/uploads/abc.jpg'));
      expect(order.photoUrl, startsWith('http'));
    });

    test('total perkiraan dipakai selama harga akhir belum ada', () {
      final order = Order.fromJson(json);

      expect(order.totalSudahFinal, isFalse);
      expect(order.totalPerkiraan, 2.5 * 7000);
    });

    test('memakai harga akhir dari server bila sudah ada', () {
      final order = Order.fromJson({
        ...json,
        'actual_weight': '3.00',
        'total_price': '21000.00',
      });

      expect(order.totalSudahFinal, isTrue);
      expect(order.totalPerkiraan, 21000);
      expect(order.sudahAdaBeratAsli, isTrue);
    });

    test('nomor pesanan memakai awalan RENOVA', () {
      expect(Order.fromJson(json).nomor, 'RNV-0007');
    });

    test('field opsional yang hilang tidak membuat parsing gagal', () {
      final order = Order.fromJson({'id': 1, 'status': 'WASHING'});

      expect(order.id, 1);
      expect(order.photoUrl, isNull);
      expect(order.paymentMethod, isNull);
      expect(order.namaLayanan, 'Layanan #0');
    });
  });

  group('ServiceItem.fromJson', () {
    test('membaca harga dan deskripsi', () {
      final layanan = ServiceItem.fromJson({
        'id': 1,
        'name': 'Setrika',
        'description': 'Disetrika rapi',
        'price_per_kg': '5000.00',
        'duration': '1 hari',
      });

      expect(layanan.name, 'Setrika');
      expect(layanan.pricePerKg, 5000);
      expect(layanan.deskripsiTampil, 'Disetrika rapi');
    });

    test('deskripsi kosong diberi teks pengganti', () {
      final layanan = ServiceItem.fromJson({
        'id': 1,
        'name': 'Setrika',
        'description': null,
        'price_per_kg': 5000,
        'duration': '1 hari',
      });

      expect(layanan.deskripsiTampil, contains('Belum ada deskripsi'));
    });
  });

  group('User.fromJson', () {
    test('membaca role ADMIN dan CUSTOMER dari API', () {
      final admin = User.fromJson({
        'id': 1,
        'name': 'Admin',
        'email': 'admin@mail.com',
        'role': 'ADMIN',
      });
      final customer = User.fromJson({
        'id': 2,
        'name': 'Budi',
        'email': 'budi@mail.com',
        'role': 'CUSTOMER',
      });

      expect(admin.role.isAdmin, isTrue);
      expect(customer.role.isAdmin, isFalse);
    });

    test('membuat inisial dari nama', () {
      User buat(String nama) => User(
            id: 1,
            name: nama,
            email: 'x@mail.com',
            role: UserRole.customer,
          );

      expect(buat('Budi Santoso').inisial, 'BS');
      expect(buat('Budi').inisial, 'B');
      expect(buat('   ').inisial, '?');
    });
  });

  group('OrderLabels', () {
    test('menerjemahkan keenam status backend', () {
      expect(OrderLabels.status('PENDING_CONFIRMATION'), 'Menunggu Konfirmasi');
      expect(OrderLabels.status('CONFIRMED'), 'Dikonfirmasi');
      expect(OrderLabels.status('WASHING'), 'Sedang Dicuci');
      expect(OrderLabels.status('READY_FOR_PICKUP'), 'Siap Diambil');
      expect(OrderLabels.status('COMPLETED'), 'Selesai');
      expect(OrderLabels.status('CANCELLED'), 'Dibatalkan');
    });

    test('status yang tidak dikenal ditampilkan apa adanya, tidak dikarang', () {
      expect(OrderLabels.status('STATUS_BARU'), 'STATUS_BARU');
      expect(OrderLabels.status(null), '—');
    });

    test('customer hanya boleh membatalkan sebelum pencucian', () {
      expect(OrderLabels.bolehDibatalkanCustomer('PENDING_CONFIRMATION'), isTrue);
      expect(OrderLabels.bolehDibatalkanCustomer('CONFIRMED'), isTrue);
      expect(OrderLabels.bolehDibatalkanCustomer('WASHING'), isFalse);
      expect(OrderLabels.bolehDibatalkanCustomer('READY_FOR_PICKUP'), isFalse);
      expect(OrderLabels.bolehDibatalkanCustomer('COMPLETED'), isFalse);
    });

    test('transisi status sama dengan aturan backend', () {
      expect(
        OrderLabels.langkahBerikutnya('PENDING_CONFIRMATION'),
        <String>['CONFIRMED', 'CANCELLED'],
      );
      expect(
        OrderLabels.langkahBerikutnya('READY_FOR_PICKUP'),
        <String>['COMPLETED', 'CANCELLED'],
      );
      expect(OrderLabels.langkahBerikutnya('COMPLETED'), isEmpty);
      expect(OrderLabels.langkahBerikutnya('CANCELLED'), isEmpty);
    });

    test('metode pembayaran dari API diterjemahkan', () {
      expect(OrderLabels.metodePembayaran('CASH'), contains('Tunai'));
      expect(OrderLabels.metodePembayaran('QRIS'), 'QRIS');
      expect(OrderLabels.metodePembayaran('BANK_TRANSFER'), contains('Transfer'));
      expect(OrderLabels.metodePembayaran('EWALLET'), contains('Dompet'));
      expect(OrderLabels.metodePembayaran(null), 'Belum dipilih');
    });

    test('status pembayaran null tidak diklaim lunas', () {
      expect(OrderLabels.statusPembayaran('PAID'), 'Lunas');
      expect(OrderLabels.statusPembayaran('UNPAID'), 'Belum dibayar');
      expect(OrderLabels.statusPembayaran(null), 'Belum tercatat');
    });
  });
}
