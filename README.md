# RENOVA — Aplikasi Laundry

Aplikasi Flutter untuk pemesanan dan manajemen laundry RENOVA, dengan dua peran
pengguna: **ADMIN** dan **CUSTOMER**. Seluruh data diambil dari REST API RENOVA
(Express + PostgreSQL) di `../Renova_Api`; tidak ada data contoh yang ditanam di
aplikasi.

## Menjalankan

```bash
flutter pub get
flutter run
```

Alamat API diambil dari `API_BASE_URL`. Tanpa nilai itu, aplikasi memakai alamat
pengembangan: `http://10.0.2.2:3000` di emulator Android dan
`http://localhost:3000` di tempat lain.

```bash
# Perangkat nyata / server
flutter run --dart-define=API_BASE_URL=https://alamat-server-anda

flutter build apk --dart-define=API_BASE_URL=https://alamat-server-anda
```

Alamat produksi belum ditentukan, jadi tidak ada URL yang dikarang di source
code. Semua konfigurasi ada di `lib/core/config/api_config.dart`.

## Pemeriksaan

```bash
flutter analyze
flutter test
flutter build web
```

## Struktur

```text
lib/
├── core/
│   ├── config/       api_config.dart — satu-satunya tempat alamat API
│   ├── di/           app_scope.dart — penyedia dependensi
│   ├── network/      api_client.dart, api_exception.dart
│   ├── state/        session_controller.dart, loadable.dart, refresh_bus.dart
│   ├── theme/        app_colors.dart, app_theme.dart
│   └── utils/        formatters.dart, validators.dart, order_labels.dart
├── data/
│   ├── models/       user.dart, service_item.dart, order.dart, json.dart
│   ├── repositories/ auth, service, order
│   └── services/     token_storage.dart, token_holder.dart, photo_picker.dart
├── features/
│   ├── authentication/ splash, login, register, root_gate
│   ├── account/        profil_tab.dart (dipakai admin & customer)
│   ├── customer/       customer_shell, home_tab, pesan_form_page,
│   │                   pesanan_tab, riwayat_tab
│   ├── admin/          admin_shell, dashboard_tab, admin_orders_tab,
│   │                   admin_services_tab, admin_riwayat_tab
│   └── orders/         order_detail_page.dart (customer & admin)
├── shared/widgets/   komponen yang dipakai bersama
└── main.dart
```

## Integrasi API

Endpoint yang dipakai, sesuai `Renova_Api`:

| Kebutuhan | Endpoint |
|---|---|
| Masuk / daftar | `POST /api/auth/login`, `POST /api/auth/register` |
| Profil | `GET /api/auth/me`, `PATCH /api/auth/me` |
| Layanan | `GET /api/services`, `GET /api/services/:id` |
| Layanan (admin) | `POST/PUT/DELETE /api/services(/:id)` |
| Pesanan (customer) | `POST /api/orders`, `GET /api/orders(/:id)` |
| Batal | `PATCH /api/orders/:id/batal` |
| Foto pesanan | `PATCH /api/orders/:id/foto`, `DELETE /api/orders/:id/foto` |
| Status (admin) | `PATCH /api/orders/:id/status` |
| Berat asli (admin) | `PATCH /api/orders/:id/berat-asli` |
| Bayar (admin) | `PATCH /api/orders/:id/bayar` |

Catatan perilaku yang diikuti aplikasi:

- **Status** memakai nilai asli API: `PENDING_CONFIRMATION`, `CONFIRMED`,
  `WASHING`, `READY_FOR_PICKUP`, `COMPLETED`, `CANCELLED`. Yang diterjemahkan
  hanya labelnya (`lib/core/utils/order_labels.dart`).
- **Pembatalan oleh customer** hanya ditawarkan pada dua status awal; tombolnya
  tetap mengirim permintaan ke server dan penolakan server ditampilkan.
- **Harga akhir** dihitung server dari berat asli. Aplikasi menampilkan nilai
  yang dikirim balik, dan menandai `est.` selama harga akhir belum ada.
- **Pembayaran non-tunai** dicatat lunas otomatis oleh backend dan masih berupa
  simulasi — bukan payment gateway. Layar menyebutkan hal ini apa adanya.
- **Foto pesanan** satu berkas per pesanan, JPEG/PNG/WebP, maksimal 2 MB, field
  multipart `photo`.

## Akun

Tidak ada kredensial yang ditanam di aplikasi. Akun admin awal mengikuti data
backend (`vinpin827@gmail.com`); registrasi dari aplikasi selalu menghasilkan
akun CUSTOMER.
