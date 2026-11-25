import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/service_item.dart';
import '../account/profil_tab.dart';
import 'home_tab.dart';
import 'pesan_form_page.dart';
import 'pesanan_tab.dart';
import 'riwayat_tab.dart';

/// Kerangka aplikasi untuk CUSTOMER: empat menu di navigasi bawah.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, this.initialIndex = 0});

  /// Menu yang dibuka pertama kali. Bawaannya Beranda.
  final int initialIndex;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _indeks = widget.initialIndex.clamp(0, 3);

  Future<void> _pesan(ServiceItem layanan) async {
    final berhasil = await PesanFormPage.buka(context, layanan);
    if (!mounted || berhasil != true) return;

    // Pesanan sudah tercatat di server: pindah ke tab Pesanan supaya
    // pengguna langsung melihat hasilnya. Tab pesanan menyegarkan dirinya
    // sendiri lewat RefreshBus.
    AppScope.of(context).refreshBus.tandaBerubah();
    setState(() => _indeks = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _indeks,
          children: [
            HomeTab(onPesan: _pesan),
            const PesananTab(),
            const RiwayatTab(),
            const ProfilTab(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          NavigationBar(
            selectedIndex: _indeks,
            onDestinationSelected: (i) => setState(() => _indeks = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Pesanan',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
