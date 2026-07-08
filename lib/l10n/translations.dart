import 'package:flutter/material.dart';
import 'ar_translations.dart';

class AppStrings {
  Locale locale;

  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final localizations = Localizations.of<AppStrings>(context, AppStrings);
    if (localizations != null) {
      return localizations;
    }
    // Fallback for uninitialized locale - use device locale or default to English
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (deviceLocale.languageCode == 'ar' ||
        deviceLocale.languageCode == 'id' ||
        deviceLocale.languageCode == 'ms') {
      return AppStrings(deviceLocale);
    }
    return AppStrings(const Locale('en'));
  }

  String get languageCode => locale.languageCode;

  String _get(Map<String, String> map) {
    // Arabic: check the map first, then fall back to the Arabic overlay
    if (locale.languageCode == 'ar') {
      final ar = map['ar'];
      if (ar != null) return ar;
      // Look up the English text in the Arabic overlay
      final enText = map['en'];
      if (enText != null) {
        final overlay = arTranslations[enText];
        if (overlay != null) return overlay;
      }
      return enText ?? '';
    }
    return map[locale.languageCode] ?? map['en'] ?? '';
  }

  // ─── Onboarding ───
  String get onboardingWelcome => _get({
        'en': 'Welcome to\n\u03A9MMON',
        'id': 'Selamat Datang di\n\u03A9MMON',
        'ms': 'Selamat Datang ke\n\u03A9MMON'
      });

  String get onboardingSubtitle => _get({
        'en': 'Open Mikrotik Monitor',
        'id': 'Buka Mikrotik Monitor',
        'ms': 'Buka Mikrotik Monitor',
      });

  String get onboardingDescription => _get({
        'en':
            'Monitor and manage your MikroTik hotspot from your phone. Generate vouchers, track users, and view real-time statistics.',
        'id':
            'Pantau dan kelola hotspot MikroTik dari ponsel Anda. Buat voucher, lacak pengguna, dan lihat statistik real-time.',
        'ms':
            'Pantau dan urus hotspot MikroTik dari telefon anda. Buat voucher, jejak pengguna, dan lihat statistik masa nyata.',
      });

  String get skip => _get({'en': 'Skip', 'id': 'Lewati', 'ms': 'Langkau'});
  String get next => _get({'en': 'Next', 'id': 'Lanjut', 'ms': 'Seterusnya'});
  String get back => _get({'en': 'Back', 'id': 'Kembali', 'ms': 'Kembali'});
  String get continue_ =>
      _get({'en': 'Continue', 'id': 'Lanjutkan', 'ms': 'Teruskan'});

  // ─── Features ───
  String get whatYouCanDo => _get({
        'en': 'What You Can Do',
        'id': 'Yang Bisa Dilakukan',
        'ms': 'Apa Yang Boleh Dilakukan'
      });

  // ─── Warning ───
  String get importantNotice => _get({
        'en': 'Important Notice',
        'id': 'Pemberitahuan Penting',
        'ms': 'Notis Penting'
      });

  String get agreeBackup => _get({
        'en': 'I have backed up my router and understand the risks',
        'id': 'Saya telah mencadangkan router dan memahami risikonya',
        'ms': 'Saya telah membuat sandar router dan memahami risiko',
      });

  // ─── Get Started ───
  String get readyToStart => _get(
      {'en': 'Ready to Start!', 'id': 'Siap Memulai!', 'ms': 'Sedia Bermula!'});

  String get connectDescription => _get({
        'en':
            'Connect your MikroTik router or try the app with demo data first.',
        'id':
            'Hubungkan router MikroTik Anda atau coba aplikasi dengan data demo terlebih dahulu.',
        'ms':
            'Sambungkan router MikroTik anda atau cuba aplikasi dengan data demo dahulu.',
      });

  String get connectToRouter => _get({
        'en': 'Connect to Router',
        'id': 'Hubungkan ke Router',
        'ms': 'Sambung ke Router'
      });
  String get saveThisRouter => _get({
        'en': 'Save this router',
        'id': 'Simpan router ini',
        'ms': 'Simpan router ini',
      });
  String get optional => _get({
        'en': 'Optional',
        'id': 'Opsional',
        'ms': 'Pilihan',
      });
  String get connect => _get({
        'en': 'Connect',
        'id': 'Hubungkan',
        'ms': 'Sambung',
      });
  String get connectionFailed => _get({
        'en': 'Connection Failed',
        'id': 'Koneksi Gagal',
        'ms': 'Sambungan Gagal',
      });

  // ─── Hotspot User Details ───
  String get userDetails => _get({
        'en': 'User Details',
        'id': 'Detail Pengguna',
        'ms': 'Butiran Pengguna'
      });
  String get name => _get({'en': 'Name', 'id': 'Nama', 'ms': 'Nama'});
  String get ipAddress =>
      _get({'en': 'IP Address', 'id': 'Alamat IP', 'ms': 'Alamat IP'});
  String get macAddress =>
      _get({'en': 'MAC Address', 'id': 'Alamat MAC', 'ms': 'Alamat MAC'});
  String get uptime => _get({'en': 'Uptime', 'id': 'Uptime', 'ms': 'Uptime'});
  String get bytesUsed => _get(
      {'en': 'Bytes Used', 'id': 'Bytes Digunakan', 'ms': 'Bytes Digunakan'});
  String get status => _get({'en': 'Status', 'id': 'Status', 'ms': 'Status'});
  String get edit => _get({'en': 'Edit', 'id': 'Edit', 'ms': 'Edit'});
  String get delete => _get({'en': 'Delete', 'id': 'Hapus', 'ms': 'Padam'});
  String get disable =>
      _get({'en': 'Disable', 'id': 'Nonaktifkan', 'ms': 'Lumpuhkan'});
  String get enable =>
      _get({'en': 'Enable', 'id': 'Aktifkan', 'ms': 'Aktifkan'});
  String get generateVoucher => _get(
      {'en': 'Generate Voucher', 'id': 'Buat Voucher', 'ms': 'Cipta Voucher'});
  String get backToHome => _get({
        'en': 'Back to Home',
        'id': 'Kembali ke Beranda',
        'ms': 'Kembali ke Laman Utama'
      });
  String get lastSeen => _get(
      {'en': 'Last Seen', 'id': 'Terakhir Dilihat', 'ms': 'Terakhir Dilihat'});
  String get connectedSince => _get({
        'en': 'Connected Since',
        'id': 'Terhubung Sejak',
        'ms': 'Disambung Sejak'
      });

  // ─── Add/Edit User ───
  String get addUserTitle => _get(
      {'en': 'Add User', 'id': 'Tambah Pengguna', 'ms': 'Tambah Pengguna'});
  String get editUserTitle =>
      _get({'en': 'Edit User', 'id': 'Edit Pengguna', 'ms': 'Edit Pengguna'});
  String get fullName =>
      _get({'en': 'Full Name', 'id': 'Nama Lengkap', 'ms': 'Nama Penuh'});
  String get passwordOptional => _get({
        'en': 'Password (optional)',
        'id': 'Kata Sandi (opsional)',
        'ms': 'Kata Laluan (pilihan)'
      });
  String get limitUptime =>
      _get({'en': 'Limit Uptime', 'id': 'Batas Uptime', 'ms': 'Had Uptime'});
  String get addUserSuccess => _get({
        'en': 'User added',
        'id': 'Pengguna ditambahkan',
        'ms': 'Pengguna ditambah'
      });
  String get editUserSuccess => _get({
        'en': 'User updated',
        'id': 'Pengguna diperbarui',
        'ms': 'Pengguna dikemaskini'
      });

  // ─── Quick Setup ───
  String get quickSetup => _get({
        'en': 'Quick Setup',
        'id': 'Pengaturan Cepat',
        'ms': 'Persediaan Pantas'
      });

  String get quickSetupDescription => _get({
        'en':
            'Set your preferences for currency and location. You can change these later in Settings.',
        'id':
            'Atur preferensi mata uang dan lokasi. Anda bisa mengubahnya nanti di Pengaturan.',
        'ms':
            'Tetapkan pilihan mata wang dan lokasi. Anda boleh mengubahnya kemudian dalam Tetapan.',
      });

  String get country => _get({'en': 'Country', 'id': 'Negara', 'ms': 'Negara'});
  String get currency =>
      _get({'en': 'Currency', 'id': 'Mata Uang', 'ms': 'Mata Wang'});
  String get companyName => _get({
        'en': 'Business Name (optional)',
        'id': 'Nama Usaha (opsional)',
        'ms': 'Nama Perniagaan (pilihan)'
      });
  String get language =>
      _get({'en': 'Language', 'id': 'Bahasa', 'ms': 'Bahasa'});
  String get selectLanguage => _get({
        'en': 'Select Your Language',
        'id': 'Pilih Bahasa Anda',
        'ms': 'Pilih Bahasa Anda'
      });
  String get saveAndContinue => _get({
        'en': 'Save & Continue',
        'id': 'Simpan & Lanjutkan',
        'ms': 'Simpan & Teruskan'
      });

  // ─── Welcome / Login ───
  String get welcomeBack => _get({
        'en': 'Welcome Back!',
        'id': 'Selamat Datang Kembali!',
        'ms': 'Selamat Datang Kembali!'
      });

  String get selectRouter => _get({
        'en': 'Select a router to connect',
        'id': 'Pilih router untuk terhubung',
        'ms': 'Pilih router untuk disambungkan',
      });

  String get enterDetails => _get({
        'en': 'Enter your router details',
        'id': 'Masukkan detail router Anda',
        'ms': 'Masukkan butiran router anda',
      });

  String get myRouters =>
      _get({'en': 'My Routers', 'id': 'Router Saya', 'ms': 'Router Saya'});
  String get connectNewRouter => _get({
        'en': 'Connect to New Router',
        'id': 'Hubungkan Router Baru',
        'ms': 'Sambung ke Router Baru'
      });
  String get noRoutersSaved => _get({
        'en': 'No routers saved yet',
        'id': 'Belum ada router tersimpan',
        'ms': 'Tiada router disimpan lagi'
      });
  String get tapToConnectFirstRouter => _get({
        'en': 'Tap below to connect your first router',
        'id': 'Sentuh di bawah untuk menghubungkan router pertama Anda',
        'ms': 'Tekan di bawah untuk menyambung router pertama anda',
      });

  String get addRouterBelow => _get({
        'en': 'Add your router below to get started',
        'id': 'Tambahkan router di bawah untuk memulai',
        'ms': 'Tambahkan router anda di bawah untuk bermula',
      });

  String get routerIP =>
      _get({'en': 'Router IP', 'id': 'Router IP', 'ms': 'Router IP'});
  String get port => _get({'en': 'Port', 'id': 'Port', 'ms': 'Port'});
  String get username =>
      _get({'en': 'Username', 'id': 'Nama Pengguna', 'ms': 'Nama Pengguna'});
  String get password =>
      _get({'en': 'Password', 'id': 'Kata Sandi', 'ms': 'Kata Laluan'});
  String get connectAndSave => _get({
        'en': 'Connect & Save',
        'id': 'Hubungkan & Simpan',
        'ms': 'Sambung & Simpan'
      });
  String get connecting => _get(
      {'en': 'Connecting...', 'id': 'Menghubungkan...', 'ms': 'Menyambung...'});
  String get enterApp =>
      _get({'en': 'ENTER APP', 'id': 'MASUK APLIKASI', 'ms': 'MASUK APLIKASI'});

  // ─── Dashboard ───
  String get dashboard =>
      _get({'en': 'Dashboard', 'id': 'Dasbor', 'ms': 'Papan Pemuka'});
  String get searchUsers => _get(
      {'en': 'Search users', 'id': 'Cari pengguna', 'ms': 'Cari pengguna'});

  // ─── Users ───
  String get hotspotUsers => _get({
        'en': 'Hotspot Users',
        'id': 'Pengguna Hotspot',
        'ms': 'Pengguna Hotspot'
      });
  String get activeUsers => _get(
      {'en': 'Active Users', 'id': 'Pengguna Aktif', 'ms': 'Pengguna Aktif'});
  String get hotspotHosts =>
      _get({'en': 'Hotspot Hosts', 'id': 'Host Hotspot', 'ms': 'Host Hotspot'});
  String get dhcpLeases =>
      _get({'en': 'DHCP Leases', 'id': 'Lease DHCP', 'ms': 'Lease DHCP'});
  String get userProfiles => _get({
        'en': 'User Profiles',
        'id': 'Profil Pengguna',
        'ms': 'Profil Pengguna'
      });
  String get files => _get({
        'en': 'Files',
        'id': 'Berkas',
        'ms': 'Fail'
      });

  // ─── Vouchers ───
  String get generateVouchers => _get(
      {'en': 'Generate Vouchers', 'id': 'Buat Voucher', 'ms': 'Cipta Voucher'});
  String get vouchers =>
      _get({'en': 'Vouchers', 'id': 'Voucher', 'ms': 'Voucher'});
  String get print => _get({'en': 'Print', 'id': 'Cetak', 'ms': 'Cetak'});
  String get noVouchersToPrint => _get({
        'en': 'No vouchers to print',
        'id': 'Tidak ada voucher untuk dicetak',
        'ms': 'Tiada voucher untuk dicetak',
      });
  String get errorLoadingVouchers => _get({
        'en': 'Error loading vouchers',
        'id': 'Error memuat voucher',
        'ms': 'Ralat memuat voucher',
      });
  String get newestFirst =>
      _get({'en': 'Newest First', 'id': 'Terbaru Dulu', 'ms': 'Terbaru Dulu'});
  String get oldestFirst =>
      _get({'en': 'Oldest First', 'id': 'Terlama Dulu', 'ms': 'Terlama Dulu'});
  String get aToZ => _get({'en': 'A to Z', 'id': 'A sampai Z', 'ms': 'A ke Z'});
  String get deleteVoucherTitle => _get({
        'en': 'Delete Voucher?',
        'id': 'Hapus Voucher?',
        'ms': 'Padam Voucher?'
      });
  String deleteVoucherMessage(String username) => _get({
        'en': 'Delete voucher "$username"?',
        'id': 'Hapus voucher "$username"?',
        'ms': 'Padam voucher "$username"?',
      });
  String get voucherDeleted => _get({
        'en': 'Voucher deleted',
        'id': 'Voucher dihapus',
        'ms': 'Voucher dipadam',
      });

  // ─── Revenue ───
  String get revenue =>
      _get({'en': 'Revenue', 'id': 'Pendapatan', 'ms': 'Pendapatan'});
  String get noTransactionsToExport => _get({
        'en': 'No transactions to export',
        'id': 'Tidak ada transaksi untuk diekspor',
        'ms': 'Tiada transaksi untuk dieksport',
      });
  String get failedToExport => _get({
        'en': 'Failed to export: %s',
        'id': 'Gagal mengekspor: %s',
        'ms': 'Gagal mengeksport: %s'
      });
  String get allProfiles =>
      _get({'en': 'All Profiles', 'id': 'Semua Profil', 'ms': 'Semua Profil'});
  String get thisWeek =>
      _get({'en': 'This Week', 'id': 'Minggu Ini', 'ms': 'Minggu Ini'});
  String get thisMonth =>
      _get({'en': 'This Month', 'id': 'Bulan Ini', 'ms': 'Bulan Ini'});
  String get thisQuarter =>
      _get({'en': 'This Quarter', 'id': 'Kuartal Ini', 'ms': 'Suku Tahun Ini'});
  String get thisYear =>
      _get({'en': 'This Year', 'id': 'Tahun Ini', 'ms': 'Tahun Ini'});
  String get dashboardNav =>
      _get({'en': 'Dashboard', 'id': 'Dasbor', 'ms': 'Papan Pemuka'});
  String get usersNav =>
      _get({'en': 'Users', 'id': 'Pengguna', 'ms': 'Pengguna'});
  String get hostsNav => _get({'en': 'Hosts', 'id': 'Host', 'ms': 'Host'});
  String get settingsNav =>
      _get({'en': 'Settings', 'id': 'Pengaturan', 'ms': 'Tetapan'});
  String get settings =>
      _get({'en': 'Settings', 'id': 'Pengaturan', 'ms': 'Tetapan'});
  String get selectAllProfiles =>
      _get({'en': 'All Profiles', 'id': 'Semua Profil', 'ms': 'Semua Profil'});
  String get activityLogs =>
      _get({'en': 'Activity Logs', 'id': 'Log Aktiviti', 'ms': 'Log Aktiviti'});

  // ─── Common ───
  String get cancel => _get({'en': 'Cancel', 'id': 'Batal', 'ms': 'Batal'});
  String get save => _get({'en': 'Save', 'id': 'Simpan', 'ms': 'Simpan'});
  String get copy => _get({'en': 'Copy', 'id': 'Salin', 'ms': 'Salin'});
  String get share => _get({'en': 'Share', 'id': 'Bagikan', 'ms': 'Kongsi'});
  String get refresh =>
      _get({'en': 'Refresh', 'id': 'Segarkan', 'ms': 'Muat Semula'});
  String get retry =>
      _get({'en': 'Retry', 'id': 'Coba Lagi', 'ms': 'Cuba Lagi'});
  String get close => _get({'en': 'Close', 'id': 'Tutup', 'ms': 'Tutup'});
  String get ok => _get({'en': 'OK', 'id': 'OK', 'ms': 'OK'});
  String get loading =>
      _get({'en': 'Loading...', 'id': 'Memuat...', 'ms': 'Memuatkan...'});

  // ─── Language Change ───
  String get languageChanged => _get({
        'en': 'Language changed to',
        'id': 'Bahasa diubah ke',
        'ms': 'Bahasa diubah ke',
      });
  String get restartToApply => _get({
        'en': 'Please restart the app to apply changes.',
        'id': 'Silakan restart aplikasi untuk menerapkan perubahan.',
        'ms': 'Sila restart aplikasi untuk melaksanakan perubahan.',
      });

  // ─── What's New ───
  String get whatsNew =>
      _get({"en": "What's New", 'id': 'Yang Baru', 'ms': 'Apa Yang Baru'});
  String get gotIt =>
      _get({'en': 'Got it!', 'id': 'Mengerti!', 'ms': 'Faham!'});

  // ─── Settings Details ───
  String get appearance =>
      _get({'en': 'Appearance', 'id': 'Tampilan', 'ms': 'Penampilan'});
  String get general => _get({'en': 'General', 'id': 'Umum', 'ms': 'Am'});
  String get voucherTemplates => _get({
        'en': 'Voucher Templates',
        'id': 'Template Voucher',
        'ms': 'Templat Voucher'
      });
  String get logs => _get({'en': 'Logs', 'id': 'Log', 'ms': 'Log'});
  String get connections =>
      _get({'en': 'Connections', 'id': 'Koneksi', 'ms': 'Sambungan'});
  String get account => _get({'en': 'Account', 'id': 'Akun', 'ms': 'Akaun'});
  String get about => _get({'en': 'About', 'id': 'Tentang', 'ms': 'Perihal'});

  // ─── Theme Options ───
  String get purpleTheme =>
      _get({'en': 'Purple Theme', 'id': 'Tema Ungu', 'ms': 'Tema Ungu'});
  String get lightTheme =>
      _get({'en': 'Light Theme', 'id': 'Tema Terang', 'ms': 'Tema Cerah'});
  String get blueTheme =>
      _get({'en': 'Blue Theme', 'id': 'Tema Biru', 'ms': 'Tema Biru'});
  String get greenTheme =>
      _get({'en': 'Green Theme', 'id': 'Tema Hijau', 'ms': 'Tema Hijau'});
  String get pinkTheme => _get(
      {'en': 'Pink Theme', 'id': 'Tema Merah Muda', 'ms': 'Tema Merah Jambu'});

  // ─── Theme Subtitles ───
  String get defaultVibrantPurple => _get({
        'en': 'Default vibrant purple',
        'id': 'Ungu vibransi default',
        'ms': 'Ungu vibransi Lalai'
      });
  String get cleanModernLook => _get({
        'en': 'Clean and modern look',
        'id': 'Tampilan bersih dan modern',
        'ms': 'Penampilan bersih dan moden'
      });
  String get oceanBlueVibes => _get({
        'en': 'Ocean blue vibes',
        'id': 'Vibes biru laut',
        'ms': 'Vibes biru lautan'
      });
  String get natureInspiredGreen => _get({
        'en': 'Nature inspired green',
        'id': 'Hijau terinspirasi alam',
        'ms': 'Hijau berinspirasi semula jadi'
      });
  String get romanticPinkVibes => _get({
        'en': 'Romantic pink vibes',
        'id': 'Vibes pink romantis',
        'ms': 'Vibes merah jambu romantis'
      });

  // ─── General Settings ───
  String get notSet =>
      _get({'en': 'Not set', 'id': 'Belum diatur', 'ms': 'Tidak ditetapkan'});
  String get viewUserActions => _get({
        'en': 'View user actions, connections, and transactions',
        'id': 'Lihat tindakan pengguna, koneksi, dan transaksi',
        'ms': 'Lihat tindakan pengguna, sambungan, dan transaksi'
      });
  String get savedRouters => _get({
        'en': 'Saved Routers',
        'id': 'Router Tersimpan',
        'ms': 'Router Disimpan'
      });
  String get noSavedRouters => _get({
        'en': 'No saved routers yet.\nLogin to save a connection.',
        'id': 'Belum ada router tersimpan.\nMasuk untuk menyimpan koneksi.',
        'ms':
            'Tiada router disimpan lagi.\nLog masuk untuk menyimpan sambungan.'
      });
  String get addRouter =>
      _get({'en': 'Add Router', 'id': 'Tambah Router', 'ms': 'Tambah Router'});

  // ─── Dialogs ───
  String get deleteConnectionTitle => _get({
        'en': 'Delete Connection?',
        'id': 'Hapus Koneksi?',
        'ms': 'Padam Sambungan?'
      });
  String removeConnection(String name) => _get({
        'en': 'Remove "$name" from saved connections?',
        'id': 'Hapus "$name" dari koneksi tersimpan?',
        'ms': 'Buang "$name" dari sambungan disimpan?'
      });
  String get logoutTitle =>
      _get({'en': 'Logout', 'id': 'Keluar', 'ms': 'Log Keluar'});
  String get logout =>
      _get({'en': 'Logout', 'id': 'Keluar', 'ms': 'Log Keluar'});
  String get disconnectFromRouter => _get({
        'en': 'Disconnect from router',
        'id': 'Putuskan koneksi dari router',
        'ms': 'Putus sambungan dari router'
      });
  String get confirmLogout => _get({
        'en': 'Are you sure you want to logout?',
        'id': 'Apakah Anda yakin ingin keluar?',
        'ms': 'Adakah anda pasti mahu log keluar?'
      });
  String get aboutTitle =>
      _get({'en': 'About', 'id': 'Tentang', 'ms': 'Perihal'});
  String get version => _get({'en': 'Version', 'id': 'Versi', 'ms': 'Versi'});
  String get developedBy => _get({
        'en': 'Developed by',
        'id': 'Dikembangkan oleh',
        'ms': 'Dikembangkan oleh'
      });
  String get appDescription => _get({
        'en':
            'A professional RouterOS management solution for monitoring and managing Mikrotik devices.',
        'id':
            'Solusi manajemen RouterOS profesional untuk memantau dan mengelola perangkat Mikrotik.',
        'ms':
            'Solusi pengurusan RouterOS profesional untuk pemantauan dan pengurusan peranti Mikrotik.'
      });
  String get businessName => _get(
      {'en': 'Business Name', 'id': 'Nama Usaha', 'ms': 'Nama Perniagaan'});
  String get businessNameHint => _get({
        'en': 'e.g., My WiFi Shop',
        'id': 'contoh, Toko WiFi Saya',
        'ms': 'contoh, Kedai WiFi Saya',
      });
  String get saved =>
      _get({'en': 'saved', 'id': 'tersimpan', 'ms': 'disimpan'});
  String get connectionName => _get(
      {'en': 'Connection Name', 'id': 'Nama Koneksi', 'ms': 'Nama Sambungan'});
  String get hostIPAddress => _get({
        'en': 'Host/IP Address',
        'id': 'Host/Alamat IP',
        'ms': 'Host/Alamat IP'
      });
  String get portNumber => _get({'en': 'Port', 'id': 'Port', 'ms': 'Port'});
  String get usernameField =>
      _get({'en': 'Username', 'id': 'Nama Pengguna', 'ms': 'Nama Pengguna'});
  String get passwordNote => _get({
        'en': 'Password will be required when connecting',
        'id': 'Kata sandi akan diperlukan saat menghubungkan',
        'ms': 'Kata laluan diperlukan apabila menyambung'
      });

  // ─── Router Connection Dialog ───
  String get addRouterTitle =>
      _get({'en': 'Add Router', 'id': 'Tambah Router', 'ms': 'Tambah Router'});
  String get editRouterTitle =>
      _get({'en': 'Edit Router', 'id': 'Edit Router', 'ms': 'Edit Router'});
  String get connectionNameLabel => _get({
        'en': 'Connection Name *',
        'id': 'Nama Koneksi *',
        'ms': 'Nama Sambungan *'
      });
  String get connectionNameHint => _get({
        'en': 'e.g., Office Router',
        'id': 'contoh, Router Kantor',
        'ms': 'contoh, Router Pejabat'
      });
  String get hostLabel => _get({
        'en': 'Host/IP Address *',
        'id': 'Host/Alamat IP *',
        'ms': 'Host/Alamat IP *'
      });
  String get hostHint => _get({
        'en': 'e.g., 192.168.88.1',
        'id': 'contoh, 192.168.88.1',
        'ms': 'contoh, 192.168.88.1'
      });
  String get portLabel =>
      _get({'en': 'Port *', 'id': 'Port *', 'ms': 'Port *'});
  String get portHint =>
      _get({'en': 'e.g., 8728', 'id': 'contoh, 8728', 'ms': 'contoh, 8728'});
  String get usernameLabel => _get(
      {'en': 'Username *', 'id': 'Nama Pengguna *', 'ms': 'Nama Pengguna *'});
  String get usernameHint =>
      _get({'en': 'e.g., admin', 'id': 'contoh, admin', 'ms': 'contoh, admin'});
  String get enterRouterDetails => _get({
        'en': 'Enter router connection details',
        'id': 'Masukkan detail koneksi router',
        'ms': 'Masukkan butiran sambungan router'
      });
  String get passwordNoteLong => _get({
        'en': 'Password will be required when connecting',
        'id': 'Kata sandi akan diperlukan saat menghubungkan',
        'ms': 'Kata laluan diperlukan apabila menyambung'
      });

  // ─── Action Messages ───
  String get fillAllFields => _get({
        'en': 'Please fill in all required fields',
        'id': 'Silakan isi semua field yang diperlukan',
        'ms': 'Sila isi semua medan yang diperlukan'
      });
  String get addedSuccess =>
      _get({'en': 'Added', 'id': 'Ditambahkan', 'ms': 'Ditambah'});
  String get updatedSuccess =>
      _get({'en': 'Updated', 'id': 'Diperbarui', 'ms': 'Dikemaskini'});
  String get deletedSuccess =>
      _get({'en': 'Deleted', 'id': 'Dihapus', 'ms': 'Dibuang'});

  // ─── Onboarding Pages ───
  String get pageOf => _get({
        'en': 'Page %d of %d',
        'id': 'Halaman %d dari %d',
        'ms': 'Halaman %d dari %d',
      });

  // ─── Setup Screen ───
  String get selectYourCountry => _get({
        'en': 'Select your country',
        'id': 'Pilih negara Anda',
        'ms': 'Pilih negara anda',
      });
  String get selectYourCurrency => _get({
        'en': 'Select your currency',
        'id': 'Pilih mata uang Anda',
        'ms': 'Pilih mata wang anda',
      });
  String get pleaseSelectCountryAndCurrency => _get({
        'en': 'Please select your country and currency',
        'id': 'Silakan pilih negara dan mata uang Anda',
        'ms': 'Sila pilih negara dan mata wang anda',
      });
  String get errorSavingSettings => _get({
        'en': 'Error saving settings: %s',
        'id': 'Error menyimpan pengaturan: %s',
        'ms': 'Ralat menyimpan tetapan: %s',
      });

  // ─── Onboarding General ───
  String get acceptAgreementToConnect => _get({
        'en': 'Accept the agreement above to connect a real router',
        'id': 'Terima perjanjian di atas untuk menghubungkan router sungguhan',
        'ms': 'Terima perjanjian di atas untuk menyambung router sebenar',
      });

  // ─── Onboarding Features ───
  String get featureManageUsers => _get({
        'en': 'Manage Users',
        'id': 'Kelola Pengguna',
        'ms': 'Urus Pengguna',
      });
  String get featureManageUsersDesc => _get({
        'en': 'View, add, enable/disable hotspot users',
        'id': 'Lihat, tambah, aktifkan/nonaktifkan pengguna hotspot',
        'ms': 'Lihat, tambah, hidupkan/lumpuhkan pengguna hotspot',
      });
  String get featureGenerateVouchers => _get({
        'en': 'Generate Vouchers',
        'id': 'Buat Voucher',
        'ms': 'Cipta Voucher',
      });
  String get featureGenerateVouchersDesc => _get({
        'en': 'Create printable vouchers in bulk',
        'id': 'Buat voucher yang bisa dicetak secara massal',
        'ms': 'Cipta voucher yang boleh dicetak secara pukal',
      });
  String get featureRealTimeMonitor => _get({
        'en': 'Real-time Monitor',
        'id': 'Monitor Real-time',
        'ms': 'Pantau Masa Nyata',
      });
  String get featureRealTimeMonitorDesc => _get({
        'en': 'Track CPU, memory, and traffic live',
        'id': 'Pantau CPU, memori, dan lalu lintas secara langsung',
        'ms': 'Jejak CPU, memori, dan trafik secara langsung',
      });
  String get featureRevenueTracking => _get({
        'en': 'Revenue Tracking',
        'id': 'Pelacakan Pendapatan',
        'ms': 'Penjejakan Pendapatan',
      });
  String get featureRevenueTrackingDesc => _get({
        'en': 'Log and view sales transactions',
        'id': 'Catat dan lihat transaksi penjualan',
        'ms': 'Log dan lihat transaksi jualan',
      });
  String get featureMultiRouter => _get({
        'en': 'Multi-Router',
        'id': 'Multi-Router',
        'ms': 'Multi-Router',
      });
  String get featureMultiRouterDesc => _get({
        'en': 'Connect and switch between routers',
        'id': 'Hubungkan dan bertukar antar router',
        'ms': 'Sambung dan bertukar antara router',
      });

  // ─── Onboarding Warning ───
  String get backupFirst => _get({
        'en': 'Backup First',
        'id': 'Cadangkan Pertama',
        'ms': 'Sandar Dahulu',
      });
  String get backupFirstDesc => _get({
        'en':
            'Always backup your MikroTik configuration before using this app. This app creates hotspot users and may modify your router settings.',
        'id':
            'Selalu cadangkan konfigurasi MikroTik Anda sebelum menggunakan aplikasi ini. Aplikasi ini membuat pengguna hotspot dan mungkin mengubah pengaturan router Anda.',
        'ms':
            'Sentiasa sandar konfigurasi MikroTik anda sebelum menggunakan aplikasi ini. Aplikasi ini membuat pengguna hotspot dan mungkin mengubah tetapan router anda.',
      });
  String get freshInstallRecommended => _get({
        'en': 'Fresh Install Recommended',
        'id': 'Instalasi Segar Disarankan',
        'ms': 'Pemasangan Segar Disarankan',
      });
  String get freshInstallDesc => _get({
        'en':
            'For best results, use this app with a fresh MikroTik setup or a router that hasn\'t had custom hotspot scripts. Existing scripts may conflict with the users and profiles created by this app.',
        'id':
            'Untuk hasil terbaik, gunakan aplikasi ini dengan MikroTik yang baru dipasang atau router yang belum memiliki script hotspot kustom. Script yang ada mungkin bertentangan dengan pengguna dan profil yang dibuat oleh aplikasi ini.',
        'ms':
            'Untuk hasil terbaik, gunakan aplikasi ini dengan MikroTik yang baru dipasang atau router yang belum mempunyai skrip hotspot寺院. Skrip yang ada mungkin bertentangan dengan pengguna dan profil yang dibuat oleh aplikasi ini.',
      });
  String get betaSoftware => _get(
      {'en': 'Beta Software', 'id': 'Beta Software', 'ms': 'Beta Software'});
  String get betaSoftwareDesc => _get({
        'en':
            'This app is under active development. Some features may not work as expected. Always verify changes directly on your router.',
        'id':
            'Aplikasi ini sedang dalam pengembangan aktif. Beberapa fitur mungkin tidak berfungsi sesuai harapan. Selalu verifikasi perubahan langsung di router Anda.',
        'ms':
            'Aplikasi ini sedang dalam pembangunan aktif. Beberapa ciri mungkin tidak berfungsi seperti yang diharapkan. Sentiasa sahkan perubahan terus di router anda.',
      });
  String get yourDataStaysLocal => _get({
        'en': 'Your Data Stays Local',
        'id': 'Data Anda Tetap Lokal',
        'ms': 'Data Anda Tetap Setempat',
      });
  String get yourDataStaysLocalDesc => _get({
        'en':
            'All data is stored locally on your device. We do not collect or transmit your router credentials or personal information.',
        'id':
            'Semua data disimpan secara lokal di perangkat Anda. Kami tidak mengumpulkan atau mengirimkan kredensial router atau informasi pribadi Anda.',
        'ms':
            'Semua data disimpan secara setempat di peranti anda. Kami tidak mengumpul atau menghantar kredensial router atau maklumat peribadi anda.',
      });

  // ─── Dashboard ───
  String get platform =>
      _get({'en': 'Platform', 'id': 'Platform', 'ms': 'Platform'});
  String get cpu => _get({'en': 'CPU', 'id': 'CPU', 'ms': 'CPU'});
  String get memory => _get({'en': 'Memory', 'id': 'Memori', 'ms': 'Memori'});
  String get disk => _get({'en': 'Disk', 'id': 'Disk', 'ms': 'Disk'});
  String get total => _get({'en': 'Total', 'id': 'Total', 'ms': 'Total'});
  String get used => _get({'en': 'Used', 'id': 'Digunakan', 'ms': 'Digunakan'});
  String get free => _get({'en': 'Free', 'id': 'Bebas', 'ms': 'Bebas'});
  String get connectionError => _get({
        'en': 'Connection Error',
        'id': 'Koneksi Error',
        'ms': 'Sambungan Ralat',
      });
  String get errorPrefix => _get({
        'en': 'Error: %s',
        'id': 'Error: %s',
        'ms': 'Ralat: %s',
      });
  String get noDataAvailable => _get({
        'en': 'No data available',
        'id': 'Tidak ada data tersedia',
        'ms': 'Tiada data tersedia',
      });
  String get activeSessions => _get({
        'en': 'Active Sessions',
        'id': 'Sesi Aktif',
        'ms': 'Sesi Aktif',
      });
  String get totalUsers => _get(
      {'en': 'Total Users', 'id': 'Total Pengguna', 'ms': 'Jumlah Pengguna'});
  String get revenueToday => _get({
        'en': 'Revenue Today',
        'id': 'Pendapatan Hari Ini',
        'ms': 'Pendapatan Hari Ini'
      });
  String get quickActions =>
      _get({'en': 'Quick Actions', 'id': 'Aksi Cepat', 'ms': 'Aksi Pantas'});
  String get viewAllUsers => _get({
        'en': 'View All Users',
        'id': 'Lihat Semua Pengguna',
        'ms': 'Lihat Semua Pengguna'
      });
  String get viewRevenue => _get({
        'en': 'View Revenue',
        'id': 'Lihat Pendapatan',
        'ms': 'Lihat Pendapatan'
      });
  String get systemStatus => _get(
      {'en': 'System Status', 'id': 'Status Sistem', 'ms': 'Status Sistem'});
  String get healthy => _get({'en': 'Healthy', 'id': 'Sehat', 'ms': 'Sihat'});
  String get warningStatus =>
      _get({'en': 'Warning', 'id': 'Peringatan', 'ms': 'Amaran'});
  String get criticalStatus =>
      _get({'en': 'Critical', 'id': 'Kritis', 'ms': 'Kritikal'});
  String get offline =>
      _get({'en': 'Offline', 'id': 'Luring', 'ms': 'Luar Talian'});
  String get online => _get({'en': 'Online', 'id': 'Daring', 'ms': 'Daring'});
  String get trafficMonitor => _get({
        'en': 'Traffic Monitor',
        'id': 'Monitor Lalu Lintas',
        'ms': 'Pemantau Trafik'
      });

  // ─── Hotspot Users ───
  String get hotspotUser => _get({
        'en': 'Hotspot User',
        'id': 'Pengguna Hotspot',
        'ms': 'Pengguna Hotspot'
      });
  String get searchUsersPlaceholder => _get({
        'en': 'Search for hotspot users...',
        'id': 'Cari pengguna hotspot...',
        'ms': 'Cari pengguna hotspot...',
      });
  String get noUsersFound => _get({
        'en': 'No users found',
        'id': 'Tidak ada pengguna ditemukan',
        'ms': 'Tiada pengguna ditemui',
      });
  String get errorLoadingUsers => _get({
        'en': 'Error loading users',
        'id': 'Error memuat pengguna',
        'ms': 'Ralat memuat pengguna',
      });
  String get selectMultiple => _get({
        'en': 'Select multiple',
        'id': 'Pilih beberapa',
        'ms': 'Pilih beberapa'
      });
  String get exitSelection => _get({
        'en': 'Exit selection',
        'id': 'Keluar dari pilihan',
        'ms': 'Keluar dari pilihan'
      });
  String get selectedCount => _get({
        'en': '%d selected',
        'id': '%d dipilih',
        'ms': '%d dipilih',
      });
  String get viewDetails =>
      _get({'en': 'View Details', 'id': 'Lihat Detail', 'ms': 'Lihat Detail'});
  String get editUser =>
      _get({'en': 'Edit User', 'id': 'Edit Pengguna', 'ms': 'Edit Pengguna'});
  String get disableUser => _get({
        'en': 'Disable User',
        'id': 'Nonaktifkan Pengguna',
        'ms': 'Lumpuhkan Pengguna'
      });
  String get enableUser => _get({
        'en': 'Enable User',
        'id': 'Aktifkan Pengguna',
        'ms': 'Aktifkan Pengguna'
      });
  String get deleteUser => _get(
      {'en': 'Delete User', 'id': 'Hapus Pengguna', 'ms': 'Padam Pengguna'});
  String get disableUserTitle => _get({
        'en': 'Disable User?',
        'id': 'Nonaktifkan Pengguna?',
        'ms': 'Lumpuhkan Pengguna?'
      });
  String get disableUserMessage => _get({
        'en': 'Disable this user? They will not be able to connect.',
        'id': 'Nonaktifkan pengguna ini? Mereka tidak akan bisa terhubung.',
        'ms': 'Lumpuhkan pengguna ini? Mereka tidak akan boleh menyambung.',
      });
  String get enableUserTitle => _get({
        'en': 'Enable User?',
        'id': 'Aktifkan Pengguna?',
        'ms': 'Aktifkan Pengguna?'
      });
  String get enableUserMessage => _get({
        'en': 'Enable this user? They will be able to connect.',
        'id': 'Aktifkan pengguna ini? Mereka akan bisa terhubung.',
        'ms': 'Aktifkan pengguna ini? Mereka akan boleh menyambung.',
      });
  String get deleteUsersTitle => _get({
        'en': 'Delete %d users?',
        'id': 'Hapus %d pengguna?',
        'ms': 'Padam %d pengguna?',
      });
  String get deleteUsersMessage => _get({
        'en': 'Delete %d users? This action cannot be undone.',
        'id': 'Hapus %d pengguna? Tindakan ini tidak dapat dibatalkan.',
        'ms': 'Padam %d pengguna? Tindakan ini tidak boleh dibatalkan.',
      });
  String get deletingUsers => _get({
        'en': 'Deleting %d users...',
        'id': 'Menghapus %d pengguna...',
        'ms': 'Memadam %d pengguna...',
      });
  String get disablingUsers => _get({
        'en': 'Disabling %d users...',
        'id': 'Menonaktifkan %d pengguna...',
        'ms': 'Melumpuhkan %d pengguna...',
      });
  String get enablingUsers => _get({
        'en': 'Enabling %d users...',
        'id': 'Mengaktifkan %d pengguna...',
        'ms': 'Mengaktifkan %d pengguna...',
      });
  String get userDisabled => _get({
        'en': 'User disabled',
        'id': 'Pengguna dinonaktifkan',
        'ms': 'Pengguna dilumpuhkan'
      });
  String get userEnabled => _get({
        'en': 'User enabled',
        'id': 'Pengguna diaktifkan',
        'ms': 'Pengguna diaktifkan'
      });
  String get usersDeleted => _get({
        'en': 'Users deleted',
        'id': 'Pengguna dihapus',
        'ms': 'Pengguna dipadam'
      });
  String userDisabledMsg(String name) => _get({
        'en': 'User "$name" disabled',
        'id': 'Pengguna "$name" dinonaktifkan',
        'ms': 'Pengguna "$name" dilumpuhkan',
      });
  String userEnabledMsg(String name) => _get({
        'en': 'User "$name" enabled',
        'id': 'Pengguna "$name" diaktifkan',
        'ms': 'Pengguna "$name" diaktifkan',
      });
  String userDeletedMsg(String name) => _get({
        'en': 'User "$name" deleted',
        'id': 'Pengguna "$name" dihapus',
        'ms': 'Pengguna "$name" dipadam',
      });
  String userAlreadyDisabledMsg(String name) => _get({
        'en': 'User "$name" is already disabled',
        'id': 'Pengguna "$name" sudah dinonaktifkan',
        'ms': 'Pengguna "$name" sudah dilumpuhkan',
      });
  String userAlreadyActiveMsg(String name) => _get({
        'en': 'User "$name" is already active',
        'id': 'Pengguna "$name" sudah aktif',
        'ms': 'Pengguna "$name" sudah aktif',
      });
  String get loadingProfiles => _get({
        'en': 'Loading profiles...',
        'id': 'Memuat profil...',
        'ms': 'Memuat profil...',
      });
  String get failedToLoadProfiles => _get({
        'en': 'Failed to load profiles',
        'id': 'Gagal memuat profil',
        'ms': 'Gagal memuat profil',
      });
  String get profile => _get({'en': 'Profile', 'id': 'Profil', 'ms': 'Profil'});

  // ─── User Statuses ───
  String get statusVoucher =>
      _get({'en': 'Voucher', 'id': 'Voucher', 'ms': 'Voucher'});
  String get statusManual =>
      _get({'en': 'Manual', 'id': 'Manual', 'ms': 'Manual'});
  String get statusActive =>
      _get({'en': 'Active', 'id': 'Aktif', 'ms': 'Aktif'});
  String get statusInactive =>
      _get({'en': 'Inactive', 'id': 'Tidak Aktif', 'ms': 'Tidak Aktif'});
  String get statusConnected =>
      _get({'en': 'Connected', 'id': 'Terhubung', 'ms': 'Disambung'});
  String get statusOffline =>
      _get({'en': 'Offline', 'id': 'Luring', 'ms': 'Luar Talian'});
  String get filterAll => _get({'en': 'All', 'id': 'Semua', 'ms': 'Semua'});
  String get filterActive =>
      _get({'en': 'Active', 'id': 'Aktif', 'ms': 'Aktif'});
  String get filterInactive =>
      _get({'en': 'Inactive', 'id': 'Tidak Aktif', 'ms': 'Tidak Aktif'});

  // ─── More common strings ───
  String get noProfilesAvailable => _get({
        'en': 'No profiles available',
        'id': 'Tidak ada profil tersedia',
        'ms': 'Tiada profil tersedia',
      });
  String get noProfilesAvailableCreateProfileFirst => _get({
        'en': 'No profiles available. Please create a profile first.',
        'id': 'Tidak ada profil tersedia. Silakan buat profil terlebih dahulu.',
        'ms': 'Tiada profil tersedia. Sila buat profil dahulu.'
      });
  String get userDeletedSuccessfully => _get({
        'en': 'User deleted successfully',
        'id': 'Pengguna berhasil dihapus',
        'ms': 'Pengguna berjaya dipadam',
      });

  // ─── Activity Logs ───
  String get noLogsToExport => _get({
        'en': 'No logs to export',
        'id': 'Tidak ada log untuk diekspor',
        'ms': 'Tiada log untuk dieksport',
      });
  String get exportedLogEntries => _get({
        'en': 'Exported %d log entries',
        'id': 'Diekspor %d entri log',
        'ms': 'Dieksport %d entri log',
      });
  String get clear => _get({'en': 'Clear', 'id': 'Hapus', 'ms': 'Padam'});
  String get logsCleared =>
      _get({'en': 'Logs cleared', 'id': 'Log dihapus', 'ms': 'Log dipadam'});

  // ─── More Common ───
  String get alreadyDisabled => _get({
        'en': '%s is already disabled',
        'id': '%s sudah dinonaktifkan',
        'ms': '%s sudah dilumpuhkan'
      });
  String get disabled => _get(
      {'en': '%s disabled', 'id': '%s dinonaktifkan', 'ms': '%s dilumpuhkan'});
  String get enabled =>
      _get({'en': '%s enabled', 'id': '%s diaktifkan', 'ms': '%s diaktifkan'});
  String get alreadyActive => _get({
        'en': '%s is already active',
        'id': '%s sudah aktif',
        'ms': '%s sudah aktif'
      });
  String get userDeleted => _get({
        'en': '%s deleted successfully',
        'id': '%s dihapus berhasil',
        'ms': '%s berjaya dipadam'
      });
  String get deleteProfile => _get(
      {'en': 'Delete Profile', 'id': 'Hapus Profil', 'ms': 'Padam Profil'});
  String get profileDeleted => _get({
        'en': 'Profile "%s" deleted',
        'id': 'Profil "%s" dihapus',
        'ms': 'Profil "%s" dipadam'
      });
  String get profileDetails => _get(
      {'en': 'Profile Details', 'id': 'Detail Profil', 'ms': 'Butiran Profil'});
  String get editProfile =>
      _get({'en': 'Edit Profile', 'id': 'Edit Profil', 'ms': 'Edit Profil'});
  String get addProfile =>
      _get({'en': 'Add Profile', 'id': 'Tambah Profil', 'ms': 'Tambah Profil'});
  String get failedToSaveProfile => _get({
        'en': 'Failed to save profile: %s',
        'id': 'Gagal menyimpan profil: %s',
        'ms': 'Gagal menyimpan profil: %s'
      });

  String get sharedUsers => _get({
        'en': 'Shared Users',
        'id': 'Pengguna Bersama',
        'ms': 'Pengguna Berkongsi'
      });
  String get rateLimit =>
      _get({'en': 'Rate Limit', 'id': 'Batas Rate', 'ms': 'Had Rate'});
  String get validity =>
      _get({'en': 'Validity', 'id': 'Validitas', 'ms': 'Kesahan'});
  String get price => _get({'en': 'Price', 'id': 'Harga', 'ms': 'Harga'});

  // ─── Voucher Generation ───
  String get pleaseSelectProfile => _get({
        'en': 'Please select a profile',
        'id': 'Silakan pilih profil',
        'ms': 'Sila pilih profil'
      });
  String get notConnectedLoginFirst => _get({
        'en': 'Not connected to RouterOS. Please login first.',
        'id': 'Tidak terhubung ke RouterOS. Silakan login dulu.',
        'ms': 'Tidak bersabung ke RouterOS. Sila log masuk dulu.'
      });
  String get failedToCreateUser => _get({
        'en': 'Failed to create user: %s',
        'id': 'Gagal membuat pengguna: %s',
        'ms': 'Gagal membuat pengguna: %s'
      });
  String get failedToUpdateUser => _get({
        'en': 'Failed to update user: %s',
        'id': 'Gagal memperbarui pengguna: %s',
        'ms': 'Gagal mengemaskini pengguna: %s'
      });
  String get failedToGenerateVouchers => _get({
        'en': 'Failed to generate vouchers: %s',
        'id': 'Gagal membuat voucher: %s',
        'ms': 'Gagal menjana voucher: %s'
      });
  String get usernamePasswordSeparate => _get({
        'en': 'Username & Password (Separate)',
        'id': 'Nama Pengguna & Kata Sandi (Terpisah)',
        'ms': 'Nama Pengguna & Kata Laluan (Berasingan)'
      });
  String get usernameEqualPassword => _get({
        'en': 'Username = Password (Voucher)',
        'id': 'Nama Pengguna = Kata Sandi (Voucher)',
        'ms': 'Nama Pengguna = Kata Laluan (Voucher)'
      });
  String get characters =>
      _get({'en': '%d characters', 'id': '%d karakter', 'ms': '%d aksara'});
  String get defaultNoProfilesFound => _get({
        'en': 'default (no profiles found)',
        'id': 'default (tidak ada profil ditemukan)',
        'ms': 'default (tiada profil ditemui)'
      });
  String get selectProfile => _get(
      {'en': 'Select Profile', 'id': 'Pilih Profil', 'ms': 'Pilih Profil'});
  String get showUsers => _get({
        'en': 'Show Users',
        'id': 'Tampilkan Pengguna',
        'ms': 'Tunjuk Pengguna'
      });
  String get totalVouchers =>
      _get({'en': 'Total: %d', 'id': 'Total: %d', 'ms': 'Jumlah: %d'});
  String get profileLabel =>
      _get({'en': 'Profile: %s', 'id': 'Profil: %s', 'ms': 'Profil: %s'});
  String get failedToShare => _get({
        'en': 'Failed to share: %s',
        'id': 'Gagal membagikan: %s',
        'ms': 'Gagal berkongsi: %s'
      });
  String get failedToPrint => _get({
        'en': 'Failed to print vouchers: %s',
        'id': 'Gagal mencetak voucher: %s',
        'ms': 'Gagal mencetak voucher: %s'
      });
  String get failedToCreateScreenshot => _get({
        'en': 'Failed to create screenshot: %s',
        'id': 'Gagal membuat tangkapan layar: %s',
        'ms': 'Gagal membuat截: %s'
      });
  String get vouchersCopied => _get({
        'en': '%d vouchers copied to clipboard',
        'id': '%d voucher disalin ke clipboard',
        'ms': '%d voucher disalin ke papan klip'
      });
  String get voucherCopied => _get({
        'en': 'Voucher copied to clipboard',
        'id': 'Voucher disalin ke clipboard',
        'ms': 'Voucher disalin ke papan klip'
      });
  String get credentialsCopied => _get({
        'en': 'Credentials copied to clipboard',
        'id': 'Kredensial disalin ke clipboard',
        'ms': 'Maklumat disalin ke papan klip'
      });
  String get voucherDetailsCopied => _get({
        'en': 'Voucher details copied for sharing',
        'id': 'Detail voucher disalin untuk dibagikan',
        'ms': 'Butiran voucher disalin untuk dikongsi'
      });
  String get scanVoucher => _get(
      {'en': 'Scan Voucher', 'id': 'Pindai Voucher', 'ms': 'Imbas Voucher'});
  String get copiedToClipboard => _get({
        'en': 'Copied to clipboard',
        'id': 'Disalin ke clipboard',
        'ms': 'Disalin ke papan klip'
      });

  // ─── Active Users ───
  String get logoutUser => _get({
        'en': 'Logout User',
        'id': 'Keluarkan Pengguna',
        'ms': 'Log keluar Pengguna'
      });
  String get failedToLogoutUser => _get({
        'en': 'Failed to logout user: %s',
        'id': 'Gagal mengeluarkan pengguna: %s',
        'ms': 'Gagal melog keluar pengguna: %s'
      });
  String get details =>
      _get({'en': 'Details', 'id': 'Detail', 'ms': 'Butiran'});

  // ─── Hotspot Hosts ───
  String get deviceDetails => _get({
        'en': 'Device Details',
        'id': 'Detail Perangkat',
        'ms': 'Perincian Peranti'
      });
  String get hostDetails =>
      _get({'en': 'Host Details', 'id': 'Detail Host', 'ms': 'Butiran Host'});
  String get removeHost =>
      _get({'en': 'Remove Host', 'id': 'Hapus Host', 'ms': 'Padam Host'});
  String get removeHostConfirmation => _get({
        'en': 'Remove host %s from the hotspot?',
        'id': 'Hapus host %s dari hotspot?',
        'ms': 'Padam host %s dari hotspot?'
      });
  String get hostRemovedSuccessfully => _get({
        'en': 'Host removed successfully',
        'id': 'Host berhasil dihapus',
        'ms': 'Host berjaya dipadam'
      });
  String get blockMacAddress => _get({
        'en': 'Block MAC Address',
        'id': 'Blokir Alamat MAC',
        'ms': 'Sekat Alamat MAC'
      });
  String get blockMacConfirmation => _get({
        'en': 'Block MAC address %s?',
        'id': 'Blokir alamat MAC %s?',
        'ms': 'Sekat alamat MAC %s?'
      });
  String get macAddressBlocked => _get({
        'en': 'MAC address blocked',
        'id': 'Alamat MAC diblokir',
        'ms': 'Alamat MAC disekat'
      });
  String get remove => _get({'en': 'Remove', 'id': 'Hapus', 'ms': 'Padam'});
  String get block => _get({'en': 'Block', 'id': 'Blokir', 'ms': 'Sekat'});

  // ─── User Details ───
  String get failedToRefresh => _get({
        'en': 'Failed to refresh: %s',
        'id': 'Gagal menyegarkan: %s',
        'ms': 'Gagal menyegarkan: %s'
      });
  String get deleteUserConfirmation => _get({
        'en':
            'Are you sure you want to delete user "%s"? This action cannot be undone.',
        'id':
            'Apakah Anda yakin ingin menghapus pengguna "%s"? Tindakan ini tidak dibatalkan.',
        'ms':
            'Adakah anda pasti mahu memadam pengguna "%s"? Tindakan ini tidak boleh dibuat.'
      });
  String get failedToDeleteUser => _get({
        'en': 'Failed to delete user: %s',
        'id': 'Gagal menghapus pengguna: %s',
        'ms': 'Gagal memadam pengguna: %s'
      });

  // ─── Print Preview ───
  String get previewAndPrint => _get({
        'en': 'Preview & Print',
        'id': 'Pratinjau & Cetak',
        'ms': 'Pratonton & Cetak'
      });

  // ─── Voucher Templates ───
  String get customSettings => _get({
        'en': 'Custom Settings',
        'id': 'Pengaturan Kustom',
        'ms': 'Tetapan Tersuai'
      });
  String get generate => _get({'en': 'Generate', 'id': 'Buat', 'ms': 'Jana'});
  String get printAll =>
      _get({'en': 'Print All', 'id': 'Cetak Semua', 'ms': 'Cetak Semua'});

  // ─── Login / Scanner ───
  String get findRouter => _get({
        'en': 'Find Router on Network',
        'id': 'Cari Router di Jaringan',
        'ms': 'Cari Router di Rangkaian'
      });
  String get scanFailed => _get({
        'en': 'Scan failed: %s',
        'id': 'Pemindaian gagal: %s',
        'ms': 'Imbasan gagal: %s'
      });
  String get noRoutersFound => _get({
        'en': 'No MikroTik routers found on network',
        'id': 'Tidak ada router MikroTik ditemukan di jaringan',
        'ms': 'Tiada router MikroTik ditemui di rangkaian'
      });
  String get foundRouters => _get({
        'en': 'Found %d Router(s)',
        'id': 'Ditemukan %d Router',
        'ms': 'Ditemui %d Router'
      });
  String get restApiActive => _get({
        'en': 'REST API (Active)',
        'id': 'REST API (Aktif)',
        'ms': 'REST API (Aktif)'
      });
  String get legacyApi => _get({
        'en': 'Legacy API',
        'id': 'API Lama',
        'ms': 'API Lama'
      });
  String get httpBased => _get({
        'en': 'HTTP-based (faster, ROS7 recommended)',
        'id': 'Berbasis HTTP (lebih cepat, disarankan ROS7)',
        'ms': 'Berasaskan HTTP (lebih cepat, disyorkan ROS7)'
      });
  String get socketBased => _get({
        'en': 'Socket-based (ROS6)',
        'id': 'Berbasis Socket (ROS6)',
        'ms': 'Berasaskan Socket (ROS6)'
      });
  String get showPassword => _get({
        'en': 'Show password',
        'id': 'Tampilkan kata sandi',
        'ms': 'Tunjukkan kata laluan'
      });
  String get hidePassword => _get({
        'en': 'Hide password',
        'id': 'Sembunyikan kata sandi',
        'ms': 'Sembunyikan kata laluan'
      });
  String get routerosDefaultPort => _get({
        'en': 'RouterOS API port (default: 8728)',
        'id': 'Port API RouterOS (default: 8728)',
        'ms': 'Port API RouterOS (lalai: 8728)'
      });
  String get enterRouterDetailsForm => _get({
        'en': 'Enter your Mikrotik router details',
        'id': 'Masukkan detail router Mikrotik Anda',
        'ms': 'Masukkan butiran router Mikrotik anda'
      });

  // ─── Feedback ───
  String get sendFeedback => _get({
        'en': 'Send Feedback',
        'id': 'Kirim Masukan',
        'ms': 'Hantar Maklum Balas'
      });
  String get yourName => _get({
        'en': 'Your Name',
        'id': 'Nama Anda',
        'ms': 'Nama Anda'
      });
  String get enterYourName => _get({
        'en': 'Enter your name',
        'id': 'Masukkan nama Anda',
        'ms': 'Masukkan nama anda'
      });
  String get yourFeedback => _get({
        'en': 'Your Feedback',
        'id': 'Masukan Anda',
        'ms': 'Maklum Balas Anda'
      });
  String get feedbackHint => _get({
        'en': 'Tell us what you think...',
        'id': 'Katakan apa yang Anda pikirkan...',
        'ms': 'Katakan apa yang anda fikirkan...'
      });
  String get feedbackSent => _get({
        'en': 'Feedback sent. Thank you!',
        'id': 'Masukan terkirim. Terima kasih!',
        'ms': 'Maklum balas dihantar. Terima kasih!'
      });
  String get feedbackFailed => _get({
        'en': 'Failed to open feedback form',
        'id': 'Gagal membuka formulir masukan',
        'ms': 'Gagal membuka borang maklum balas'
      });
  String get openInBrowser => _get({
        'en': 'Open in Browser',
        'id': 'Buka di Peramban',
        'ms': 'Buka dalam Pelayar'
      });

  // ─── Activity Logs ───
  String get exportCsv => _get({
        'en': 'Export CSV',
        'id': 'Ekspor CSV',
        'ms': 'Eksport CSV'
      });
  String get searchLogs => _get({
        'en': 'Search logs...',
        'id': 'Cari log...',
        'ms': 'Cari log...'
      });
  String get failedToLoadLogs => _get({
        'en': 'Failed to load logs',
        'id': 'Gagal memuat log',
        'ms': 'Gagal memuat log'
      });
  String get clearAllLogs => _get({
        'en': 'Clear all logs?',
        'id': 'Hapus semua log?',
        'ms': 'Padam semua log?'
      });
  String get actionCannotBeUndone => _get({
        'en': 'This action cannot be undone.',
        'id': 'Tindakan ini tidak dapat dibatalkan.',
        'ms': 'Tindakan ini tidak boleh dibatalkan.'
      });
  String get apply => _get({
        'en': 'Apply',
        'id': 'Terapkan',
        'ms': 'Guna'
      });
  String get untilDate => _get({
        'en': 'Until %s',
        'id': 'Hingga %s',
        'ms': 'Sehingga %s'
      });
  String get allTime => _get({
        'en': 'All Time',
        'id': 'Sepanjang Masa',
        'ms': 'Sepanjang Masa'
      });
  String get justNow => _get({
        'en': 'Just now',
        'id': 'Baru saja',
        'ms': 'Baru sahaja'
      });
  String get noUsersFoundForQuery => _get({
        'en': 'No users found for "%s"',
        'id': 'Tidak ada pengguna ditemukan untuk "%s"',
        'ms': 'Tiada pengguna ditemui untuk "%s"'
      });

  // ─── Dashboard Widgets ───
  String get networkTraffic => _get({
        'en': 'Network Traffic',
        'id': 'Lalu Lintas Jaringan',
        'ms': 'Trafik Rangkaian'
      });
  String get live => _get({'en': 'LIVE', 'id': 'LANGSUNG', 'ms': 'LANGSUNG'});
  String get systemResources => _get(
      {'en': 'System Resources', 'id': 'Sumber Sistem', 'ms': 'Sumber Sistem'});
  String get moreInterfaces => _get({
        'en': '+%d more interfaces',
        'id': '+%d antarmuka lainnya',
        'ms': '+%d antara muka lagi'
      });
  String get tapToCollapse => _get({
        'en': 'Tap to collapse',
        'id': 'Ketuk untuk meruntuhkan',
        'ms': 'Ketuk untuk runtuhkan'
      });

  // ─── PDF Templates Editor ───
  String get pdfTemplatesEditor => _get({
        'en': 'PDF Templates Editor',
        'id': 'Editor Template PDF',
        'ms': 'Editor Templat PDF'
      });
  String get templateName => _get({
        'en': 'Template Name',
        'id': 'Nama Template',
        'ms': 'Nama Templat'
      });
  String get templateType => _get({
        'en': 'Template Type',
        'id': 'Jenis Template',
        'ms': 'Jenis Templat'
      });
  String get fullSize => _get({
        'en': 'Full Size',
        'id': 'Ukuran Penuh',
        'ms': 'Saiz Penuh'
      });
  String get compact => _get({
        'en': 'Compact',
        'id': 'Kompak',
        'ms': 'Padat'
      });
  String get minimal => _get({
        'en': 'Minimal',
        'id': 'Minimal',
        'ms': 'Minimum'
      });
  String get backgroundColor => _get({
        'en': 'Background Color',
        'id': 'Warna Latar',
        'ms': 'Warna Latar Belakang'
      });
  String get textColor => _get({
        'en': 'Text Color',
        'id': 'Warna Teks',
        'ms': 'Warna Teks'
      });
  String get showQrCode => _get({
        'en': 'Show QR Code',
        'id': 'Tampilkan Kode QR',
        'ms': 'Tunjuk Kod QR'
      });
  String get showLogo => _get({
        'en': 'Show Logo',
        'id': 'Tampilkan Logo',
        'ms': 'Tunjuk Logo'
      });
  String get showPrice => _get({
        'en': 'Show Price',
        'id': 'Tampilkan Harga',
        'ms': 'Tunjuk Harga'
      });
  String get showValidity => _get({
        'en': 'Show Validity',
        'id': 'Tampilkan Validitas',
        'ms': 'Tunjuk Sah'
      });
  String get showProfile => _get({
        'en': 'Show Profile',
        'id': 'Tampilkan Profil',
        'ms': 'Tunjuk Profil'
      });
  String get addTemplate => _get({
        'en': 'Add Template',
        'id': 'Tambah Template',
        'ms': 'Tambah Templat'
      });
  String get editTemplate => _get({
        'en': 'Edit Template',
        'id': 'Edit Template',
        'ms': 'Edit Templat'
      });
  String get deleteTemplate => _get({
        'en': 'Delete Template?',
        'id': 'Hapus Template?',
        'ms': 'Padam Templat?'
      });
  String get templateSaved => _get({
        'en': 'Template saved',
        'id': 'Template disimpan',
        'ms': 'Templat disimpan'
      });
  String get templateDeleted => _get({
        'en': 'Template deleted',
        'id': 'Template dihapus',
        'ms': 'Templat dipadam'
      });
  String get noTemplatesFound => _get({
        'en': 'No templates found',
        'id': 'Tidak ada template',
        'ms': 'Tiada templat dijumpai'
      });
  String get setAsDefault => _get({
        'en': 'Set as Default',
        'id': 'Jadikan Default',
        'ms': 'Tetapkan sebagai Lalai'
      });
  String get preview => _get({
        'en': 'Preview',
        'id': 'Pratinjau',
        'ms': 'Pratonton'
      });
  String get saveTemplate => _get({
        'en': 'Save Template',
        'id': 'Simpan Template',
        'ms': 'Simpan Templat'
      });

  // ─── Process Image (OCR) ───
  String get processImageOcr => _get({
        'en': 'Process Image (OCR)',
        'id': 'Proses Gambar (OCR)',
        'ms': 'Proses Imej (OCR)'
      });
  String get takePhoto => _get({
        'en': 'Take Photo',
        'id': 'Ambil Foto',
        'ms': 'Ambil Gambar'
      });
  String get chooseFromGallery => _get({
        'en': 'Choose from Gallery',
        'id': 'Pilih dari Galeri',
        'ms': 'Pilih dari Galeri'
      });
  String get recognizedText => _get({
        'en': 'Recognized Text',
        'id': 'Teks Dikenali',
        'ms': 'Teks Dikenali'
      });
  String get noTextFoundInImage => _get({
        'en': 'No text found in image',
        'id': 'Tidak ada teks dalam gambar',
        'ms': 'Tiada teks dijumpai dalam imej'
      });
  String get copyText => _get({
        'en': 'Copy Text',
        'id': 'Salin Teks',
        'ms': 'Salin Teks'
      });

  // ─── Backup System ───
  String get backupSystem => _get({
        'en': 'Backup System',
        'id': 'Sistem Backup',
        'ms': 'Sistem Sandar'
      });
  String get createBackup => _get({
        'en': 'Create Backup',
        'id': 'Buat Backup',
        'ms': 'Buat Sandar'
      });
  String get restoreBackup => _get({
        'en': 'Restore Backup',
        'id': 'Pulihkan Backup',
        'ms': 'Pulihkan Sandar'
      });
  String get downloadBackup => _get({
        'en': 'Download Backup',
        'id': 'Unduh Backup',
        'ms': 'Muat Turun Sandar'
      });
  String get backupCreatedSuccessfully => _get({
        'en': 'Backup created successfully',
        'id': 'Backup berhasil dibuat',
        'ms': 'Sandar berjaya dibuat'
      });
  String get backupRestoredSuccessfully => _get({
        'en': 'Backup restored successfully',
        'id': 'Backup berhasil dipulihkan',
        'ms': 'Sandar berjaya dipulihkan'
      });
  String get backupDeletedSuccessfully => _get({
        'en': 'Backup deleted successfully',
        'id': 'Backup berhasil dihapus',
        'ms': 'Sandar berjaya dipadam'
      });
  String get noBackupsFound => _get({
        'en': 'No backups found',
        'id': 'Tidak ada backup',
        'ms': 'Tiada sandar dijumpai'
      });
  String get backupName => _get({
        'en': 'Backup Name',
        'id': 'Nama Backup',
        'ms': 'Nama Sandar'
      });
  String get restoreFromThisBackup => _get({
        'en': 'Restore from this backup?',
        'id': 'Pulihkan dari backup ini?',
        'ms': 'Pulihkan dari sandar ini?'
      });
  String get thisWillOverwriteCurrentRouterConfiguration => _get({
        'en': 'This will overwrite current router configuration.',
        'id': 'Ini akan menimpa konfigurasi router saat ini.',
        'ms': 'Ini akan menulis ganti konfigurasi router semasa.'
      });
  String get deleteBackup => _get({
        'en': 'Delete Backup?',
        'id': 'Hapus Backup?',
        'ms': 'Padam Sandar?'
      });
}
