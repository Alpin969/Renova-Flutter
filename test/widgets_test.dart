import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:renova/core/theme/app_theme.dart';
import 'package:renova/data/models/order.dart';
import 'package:renova/shared/widgets/feedback.dart';
import 'package:renova/shared/widgets/order_row.dart';
import 'package:renova/shared/widgets/status_badge.dart';

Widget _bungkus(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Order _pesanan({String status = 'PENDING_CONFIRMATION'}) {
  return Order(
    id: 12,
    userId: 3,
    serviceId: 1,
    serviceName: 'Cuci Kering',
    customerName: 'Budi Santoso',
    estimatedWeight: 2.5,
    pricePerKg: 7000,
    status: status,
    paymentMethod: 'CASH',
    paymentStatus: 'UNPAID',
    createdAt: DateTime(2026, 11, 12, 14, 5),
  );
}

void main() {
  group('StatusBadge', () {
    testWidgets('menampilkan label status yang mudah dipahami', (tester) async {
      await tester.pumpWidget(
        _bungkus(const StatusBadge(status: 'PENDING_CONFIRMATION')),
      );

      expect(find.text('Menunggu Konfirmasi'), findsOneWidget);
    });

    testWidgets('menampilkan status pembayaran terpisah', (tester) async {
      await tester.pumpWidget(
        _bungkus(const StatusBadge.pembayaran(status: 'UNPAID')),
      );

      expect(find.text('Belum dibayar'), findsOneWidget);
    });
  });

  group('OrderRow', () {
    testWidgets('menampilkan nomor, layanan, tanggal, dan total', (tester) async {
      await tester.pumpWidget(
        _bungkus(
          OrderRow(order: _pesanan(), onTap: () {}),
        ),
      );

      expect(find.text('Cuci Kering'), findsOneWidget);
      expect(find.text('RNV-0012'), findsOneWidget);
      expect(find.text('12 Nov 2026, 14:05'), findsOneWidget);
      expect(find.text('Rp 17.500'), findsOneWidget);
      expect(find.text('Tunai · Belum dibayar'), findsOneWidget);
    });

    testWidgets('menampilkan nama customer bila diminta admin', (tester) async {
      await tester.pumpWidget(
        _bungkus(
          OrderRow(
            order: _pesanan(),
            tampilkanCustomer: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('RNV-0012 · Budi Santoso'), findsOneWidget);
    });

    testWidgets('menandai total perkiraan selama harga akhir belum ada',
        (tester) async {
      await tester.pumpWidget(
        _bungkus(OrderRow(order: _pesanan(), onTap: () {})),
      );

      expect(find.text('est.'), findsOneWidget);
    });

    testWidgets('tap pada baris memanggil aksi', (tester) async {
      var diketuk = false;

      await tester.pumpWidget(
        _bungkus(
          OrderRow(
            order: _pesanan(),
            onTap: () => diketuk = true,
          ),
        ),
      );

      await tester.tap(find.text('Cuci Kering'));
      expect(diketuk, isTrue);
    });
  });

  group('StateMessage', () {
    testWidgets('menyebut sebab dan langkah berikutnya', (tester) async {
      var dicoba = false;

      await tester.pumpWidget(
        _bungkus(
          StateMessage(
            judul: 'Belum ada pesanan',
            pesan: 'Buat pesanan dari beranda.',
            labelAksi: 'Coba lagi',
            onAksi: () => dicoba = true,
          ),
        ),
      );

      expect(find.text('Belum ada pesanan'), findsOneWidget);
      expect(find.text('Buat pesanan dari beranda.'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      expect(dicoba, isTrue);
    });

    testWidgets('tanpa aksi tidak menampilkan tombol', (tester) async {
      await tester.pumpWidget(
        _bungkus(
          const StateMessage(judul: 'Kosong', pesan: 'Tidak ada data.'),
        ),
      );

      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
