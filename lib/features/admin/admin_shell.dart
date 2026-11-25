import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../account/profil_tab.dart';
import 'admin_orders_tab.dart';
import 'admin_riwayat_tab.dart';
import 'admin_services_tab.dart';
import 'dashboard_tab.dart';

/// Kerangka aplikasi untuk ADMIN: lima menu di navigasi bawah.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _indeks = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _indeks,
          children: const [
            DashboardTab(),
            AdminOrdersTab(),
            AdminServicesTab(),
            AdminRiwayatTab(),
            ProfilTab(),
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
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Pesanan',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_laundry_service_outlined),
                selectedIcon: Icon(Icons.local_laundry_service),
                label: 'Layanan',
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
