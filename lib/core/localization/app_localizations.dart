import 'package:flutter/material.dart';

/// Lightweight, compile-safe localization for Indonesian and English.
///
/// Keeping the dictionary in Dart makes it easy to use translated strings in
/// tests without a code-generation step, while `t(id, en)` forces every screen
/// to be explicit about both languages.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [Locale('id'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isId => locale.languageCode != 'en';

  String t(String id, String en) => isId ? id : en;

  String get languageName => isId ? 'Bahasa Indonesia' : 'English';

  String get appName => 'Singgah';

  String get tagline => t(
    'Diingetin pas di tempatnya, bukan pas lupa.',
    'Reminded right where it matters, not when you forget.',
  );

  String get taglineShort =>
      t('Ingat di tempat yang tepat.', 'Remember in the right place.');

  // Navigation
  String get home => t('Beranda', 'Home');
  String get places => t('Titik', 'Places');
  String get missions => t('Misi', 'Missions');
  String get titipan => t('Titipan', 'Notes');
  String get history => t('Riwayat', 'History');
  String get settings => t('Pengaturan', 'Settings');
  String get profile => t('Profil', 'Profile');
  String get openSettings => t('Buka pengaturan', 'Open settings');

  // Auth
  String get welcomeBack => t('Selamat datang kembali', 'Welcome back');
  String get authSubtitle => t(
    'Masuk supaya Titik, Misi, dan Titipanmu tetap ada di semua perangkat.',
    'Sign in so your Places, Missions, and Notes stay with you everywhere.',
  );
  String get email => t('Email', 'Email');
  String get password => t('Kata sandi', 'Password');
  String get displayName => t('Nama tampilan', 'Display name');
  String get signIn => t('Masuk', 'Sign in');
  String get signUp => t('Daftar', 'Sign up');
  String get createAccount => t('Buat akun', 'Create account');
  String get continueWithGoogle =>
      t('Lanjut dengan Google', 'Continue with Google');
  String get orDivider => t('atau', 'or');
  String get noAccount => t('Belum punya akun?', "Don't have an account?");
  String get haveAccount => t('Sudah punya akun?', 'Already have an account?');
  String get tryDemo => t('Coba mode demo', 'Try demo mode');
  String get demoMode => t('Mode demo', 'Demo mode');
  String get demoModeBody => t(
    'Data tersimpan di perangkat saja. Hubungkan Appwrite untuk sinkron dan Titipan realtime.',
    'Data stays on this device. Connect Appwrite for sync and realtime Notes.',
  );
  String get demoUser => t('Tamu Singgah', 'Singgah Guest');
  String get signOut => t('Keluar', 'Sign out');
  String get signOutConfirm => t(
    'Keluar dari akun ini? Data lokal akan dibersihkan.',
    'Sign out of this account? Local data will be cleared.',
  );
  String get authEmailRequired =>
      t('Isi email yang valid.', 'Enter a valid email.');
  String get authPasswordRequired => t(
    'Kata sandi minimal 6 karakter.',
    'Password needs at least 6 characters.',
  );
  String get authNameRequired =>
      t('Isi nama tampilan.', 'Enter a display name.');
  String get authInvalid =>
      t('Email atau kata sandi salah.', 'The email or password is incorrect.');
  String get authErrorGeneric => t(
    'Tidak bisa masuk sekarang. Coba lagi.',
    'Could not sign in right now. Please try again.',
  );
  String get authEmailInUse =>
      t('Email ini sudah terdaftar.', 'This email is already registered.');
  String get authEmailNotConfirmed => t(
    'Cek email untuk konfirmasi akun.',
    'Check your email to confirm the account.',
  );
  String get authRateLimited => t(
    'Terlalu banyak percobaan. Coba lagi nanti.',
    'Too many attempts. Please try again later.',
  );
  String get authNetwork => t(
    'Tidak bisa menghubungi server. Periksa koneksi.',
    'Could not reach the server. Check your connection.',
  );
  String get authCloudMissing => t(
    'Cloud belum dikonfigurasi. Pakai mode demo atau isi endpoint dan project Appwrite.',
    'Cloud is not configured. Use demo mode or add the Appwrite endpoint and project ID.',
  );
  String get authGoogleBrowser => t(
    'Login Google dibuka di browser. Aplikasi akan lanjut otomatis setelah selesai.',
    'Google sign-in opened in the browser. The app will continue automatically.',
  );

  // Onboarding and permissions
  String get onboardingEyebrow => t('KENALAN DULU', 'GET ACQUAINTED');
  String get onboardingTitle => t(
    'Lokasi dipakai seperlunya, bukan terus-terusan.',
    'Location used only when needed, not all the time.',
  );
  String get onboardingBody => t(
    'Singgah memakai geofence bawaan Android. Sistem yang membangunkan aplikasi saat kamu tiba atau meninggalkan Titik — tanpa melacak rute atau lokasi terus-menerus.',
    'Singgah uses Android native geofences. The system wakes the app when you arrive at or leave a Place — without tracking routes or your location continuously.',
  );
  String get permissionForeground =>
      t('Izin lokasi saat aplikasi dipakai', 'Location while using the app');
  String get permissionForegroundBody => t(
    'Untuk menentukan Titik di sekitarmu dan menyiapkan geofence.',
    'To find Places around you and prepare geofences.',
  );
  String get permissionBackground =>
      t('Izin lokasi sepanjang waktu', 'Allow all the time');
  String get permissionBackgroundBody => t(
    'Supaya Misi tetap berbunyi saat aplikasi sedang ditutup. Di Android 11+, izin ini diatur lewat halaman pengaturan.',
    'So Missions still fire when the app is closed. On Android 11+, this is granted from the settings page.',
  );
  String get permissionNotifications =>
      t('Izin notifikasi', 'Notification permission');
  String get permissionNotificationsBody => t(
    'Untuk menampilkan pengingat dan Titipan tepat waktu.',
    'To show reminders and Notes right on time.',
  );
  String get permissionGranted => t('Diizinkan', 'Allowed');
  String get permissionMissing => t('Belum diizinkan', 'Not allowed yet');
  String get allowNow => t('Izinkan', 'Allow');
  String get openSystemSettings =>
      t('Buka pengaturan sistem', 'Open system settings');
  String get continueWithoutLocation =>
      t('Lanjut tanpa lokasi', 'Continue without location');
  String get permissionExplanation => t(
    'Kami tidak pernah membagikan lokasi real-time-mu ke siapa pun.',
    'We never share your real-time location with anyone.',
  );
  String get permissionOnlyAndroid => t(
    'Geofence hanya tersedia di Android. Di web, Titik dan Misi tetap bisa dikelola.',
    'Geofences are Android-only. On the web you can still manage Places and Missions.',
  );
  String get permissionDeniedTitle =>
      t('Izin lokasi belum aktif', 'Location permission is not active');
  String get permissionDeniedBody => t(
    'Misi tidak akan berbunyi otomatis. Kamu tetap bisa membuat dan mengelola Titik serta Misi.',
    'Missions will not fire automatically. You can still create and manage Places and Missions.',
  );
  String get gpsOffTitle => t('GPS sedang mati', 'GPS is off');
  String get gpsOffBody => t(
    'Nyalakan GPS supaya Singgah bisa mengenali saat kamu tiba atau pergi.',
    'Turn on GPS so Singgah can recognise when you arrive or leave.',
  );
  String get locationUnavailable => t(
    'Lokasi belum tersedia. Coba lagi atau pilih titik di peta.',
    'Location is not available yet. Try again or pick a point on the map.',
  );
  String get inaccurateLocation => t(
    'Akurasi lokasi rendah. Geofence tetap dipasang, tapi bisa terasa terlambat.',
    'Location accuracy is low. The geofence is still registered but may feel delayed.',
  );
  String get enableLocationServices =>
      t('Buka pengaturan lokasi', 'Open location settings');
  String get notNow => t('Nanti saja', 'Not now');

  // Home
  String get greetingMorning => t('Selamat pagi', 'Good morning');
  String get greetingAfternoon => t('Selamat siang', 'Good afternoon');
  String get greetingEvening => t('Selamat malam', 'Good evening');
  String get homeSubtitle => t(
    'Misi yang aktif di sekitarmu, siap berbunyi di tempat yang tepat.',
    'Active Missions around you, ready to speak up in the right place.',
  );
  String get nearestMissions => t('Misi terdekat', 'Nearest Missions');
  String get noMissionsToday =>
      t('Belum ada Misi aktif.', 'No active Missions yet.');
  String get noMissionsBody => t(
    'Buat Misi pertamamu, lalu tempelkan ke sebuah Titik.',
    'Create your first Mission and attach it to a Place.',
  );
  String get createFirstMission =>
      t('Buat Misi pertama', 'Create your first Mission');
  String get activeMissions => t('Misi aktif', 'Active Missions');
  String get todaySchedule => t('Jadwal hari ini', 'Today\'s schedule');
  String get recentHistory => t('Singgah terakhir', 'Recent stops');
  String get recentTitipan => t('Titipan terbaru', 'Recent Notes');
  String get quickActions => t('Aksi cepat', 'Quick actions');
  String get quickNatural => t('Ketik natural', 'Type naturally');
  String get quickPlace => t('Tambah Titik', 'Add Place');
  String get quickMission => t('Buat Misi', 'New Mission');
  String get quickTitipan => t('Titipkan pesan', 'Leave a Note');
  String get privacyCardTitle =>
      t('Kendali lokasi ada di tanganmu', 'Location stays in your hands');
  String get privacyCardBody => t(
    'Geofence dipasang oleh sistem Android. Riwayat Singgah tidak diunggah dan tidak dibagikan.',
    'Geofences are registered by Android. Stop history is never uploaded or shared.',
  );
  String get locationPausedTitle =>
      t('Pengingat lokasi sedang tidak aktif', 'Location reminders are paused');
  String get locationPausedBody => t(
    'Aktifkan izin lokasi atau nyalakan GPS supaya Misi bisa berbunyi.',
    'Enable location permission or turn on GPS so Missions can fire.',
  );
  String get geofenceWebTitle => t(
    'Pengingat lokasi hanya di Android',
    'Location reminders are Android-only',
  );
  String get geofenceWebBody => t(
    'Di web kamu bisa mengelola Titik, Misi, dan Titipan. Buka Singgah di Android untuk mengaktifkan geofence.',
    'On the web you can manage Places, Missions, and Notes. Open Singgah on Android to enable geofences.',
  );
  String get viewDetails => t('Lihat detail', 'View details');
  String get managePermissions => t('Atur izin', 'Manage permissions');
  String get stopAllReminders =>
      t('Jeda semua pengingat', 'Pause all reminders');
  String get stopAllConfirm => t(
    'Semua Misi akan dinonaktifkan. Kamu bisa mengaktifkannya lagi kapan saja.',
    'All Missions will be paused. You can turn them back on anytime.',
  );
  String get allRemindersPaused =>
      t('Semua pengingat dijeda.', 'All reminders paused.');
  String get allRemindersActive =>
      t('Semua pengingat diaktifkan.', 'All reminders active.');

  // Places
  String get placesSubtitle => t(
    'Titik adalah tempat yang kamu kenali: rumah, kantor, kampus, toko langganan.',
    'Places are spots you know: home, office, campus, your usual shop.',
  );
  String get newPlace => t('Titik baru', 'New Place');
  String get editPlace => t('Ubah Titik', 'Edit Place');
  String get placeName => t('Nama Titik', 'Place name');
  String get placeNameHint => t(
    'Contoh: Rumah, Kantor, Alfamart dekat rumah',
    'e.g. Home, Office, Alfamart near home',
  );
  String get placeAddress => t('Alamat', 'Address');
  String get placeAddressHint =>
      t('Alamat atau patokan (opsional)', 'Address or landmark (optional)');
  String get radius => t('Radius', 'Radius');
  String get iconLabel => t('Ikon', 'Icon');
  String get radiusHint => t(
    'Semakin besar radius, semakin cepat terdeteksi — tapi bisa lebih sering salah tempat.',
    'A larger radius detects sooner but may trigger in the wrong spot.',
  );
  String get searchPlace => t('Cari tempat', 'Search places');
  String get searchPlaceHint =>
      t('Cari minimarket, kampus, stasiun…', 'Search a shop, campus, station…');
  String get searchEmpty => t('Tempat tidak ditemukan.', 'No places found.');
  String get searchError =>
      t('Pencarian sedang tidak tersedia.', 'Search is unavailable right now.');
  String get pickOnMap => t('Pilih di peta', 'Pick on map');
  String get useMyLocation => t('Pakai lokasi saya', 'Use my location');
  String get mapAttribution => '© OpenStreetMap contributors';
  String get savePlace => t('Simpan Titik', 'Save Place');
  String get placeSaved => t('Titik tersimpan.', 'Place saved.');
  String get placeDeleted => t('Titik dihapus.', 'Place deleted.');
  String get deletePlace => t('Hapus Titik?', 'Delete Place?');
  String get deletePlaceBody => t(
    'Misi dan Titipan yang memakai Titik ini juga akan kehilangan lokasinya.',
    'Missions and Notes attached to this Place will lose their location.',
  );
  String get noPlaces => t('Belum ada Titik.', 'No Places yet.');
  String get noPlacesBody => t(
    'Tambahkan rumah atau kantor dulu supaya Misi punya tempat untuk berbunyi.',
    'Add home or office first so Missions have a place to fire.',
  );
  String get addPlace => t('Tambah Titik', 'Add Place');
  String get placeRequired =>
      t('Pilih Titik untuk Misi ini.', 'Choose a Place for this Mission.');
  String get placeNameRequired => t('Isi nama Titik.', 'Enter a Place name.');
  String get locationRequired => t(
    'Pilih lokasi di peta atau cari tempat.',
    'Pick a location on the map or search.',
  );
  String radiusLabel(int meters) => t('Radius $meters m', '$meters m radius');
  String get nearYou => t('Di sekitarmu', 'Near you');
  String get savedPlaces => t('Titik tersimpan', 'Saved Places');
  String placeHasMissions(int count) =>
      t('$count Misi terhubung', '$count Missions linked');
  String get mapHint => t(
    'Geser peta dan ketuk untuk memilih titik.',
    'Move the map and tap to choose a point.',
  );

  // Missions
  String get missionsSubtitle => t(
    'Misi Singgah berbunyi saat kamu tiba atau meninggalkan sebuah Titik.',
    'A Singgah Mission speaks up when you arrive at or leave a Place.',
  );
  String get newMission => t('Misi baru', 'New Mission');
  String get editMission => t('Ubah Misi', 'Edit Mission');
  String get missionTitle => t('Judul Misi', 'Mission title');
  String get missionTitleHint =>
      t('Contoh: Kirim laporan pagi', 'e.g. Send the morning report');
  String get missionNote => t('Catatan (opsional)', 'Note (optional)');
  String get missionNoteHint =>
      t('Detail kecil yang ingin diingat…', 'A small detail to remember…');
  String get trigger => t('Saat', 'When');
  String get triggerArrive => t('Tiba', 'Arrive');
  String get triggerLeave => t('Meninggalkan', 'Leave');
  String get triggerArriveLong => t('Saat tiba di', 'When arriving at');
  String get triggerLeaveLong => t('Saat meninggalkan', 'When leaving');
  String get window => t('Jendela waktu', 'Time window');
  String get windowHint => t(
    'Misi hanya berbunyi di antara jam ini.',
    'Missions only fire between these hours.',
  );
  String get repeat => t('Ulangi', 'Repeat');
  String get everyDay => t('Setiap hari', 'Every day');
  String get weekdays => t('Hari kerja', 'Weekdays');
  String get weekends => t('Akhir pekan', 'Weekends');
  String get repeatDays => t('Hari tertentu', 'Specific days');
  String get active => t('Aktif', 'Active');
  String get paused => t('Dijeda', 'Paused');
  String get saveMission => t('Simpan Misi', 'Save Mission');
  String get missionSaved => t('Misi tersimpan.', 'Mission saved.');
  String get missionDeleted => t('Misi dihapus.', 'Mission deleted.');
  String get deleteMission => t('Hapus Misi?', 'Delete Mission?');
  String get deleteMissionBody => t(
    'Misi ini tidak akan berbunyi lagi di perangkatmu.',
    'This Mission will no longer fire on your device.',
  );
  String get noMissions => t('Belum ada Misi.', 'No Missions yet.');
  String get missionTitleRequired =>
      t('Isi judul Misi.', 'Enter a Mission title.');
  String get windowInvalid => t(
    'Jam selesai harus berbeda dari jam mulai.',
    'End time must differ from start time.',
  );
  String get missionActiveHint => t(
    'Misi dijeda tetap tersimpan, tapi tidak didaftarkan sebagai geofence.',
    'Paused Missions are kept but not registered as geofences.',
  );
  String get geofenceLimitReached => t(
    'Batas geofence Android tercapai. Misi terjauh otomatis tidak didaftarkan sampai kamu mendekat.',
    'Android geofence limit reached. The farthest Missions stay unregistered until you get closer.',
  );
  String registeredGeofences(int count) =>
      t('$count geofence terdaftar', '$count geofences registered');
  String nextWindow(String time) => t('Berikutnya $time', 'Next $time');
  String get outsideWindow =>
      t('Di luar jendela waktu', 'Outside the time window');
  String get inactiveNow => t('Tidak aktif hari ini', 'Not active today');
  String get nowActive => t('Aktif sekarang', 'Active now');
  String get filterAll => t('Semua', 'All');
  String get filterActive => t('Aktif', 'Active');
  String get filterPaused => t('Dijeda', 'Paused');

  // Titipan
  String get titipanSubtitle => t(
    'Tinggalkan pesan di sebuah Titik. Pesan muncul di HP penerima saat mereka tiba.',
    'Leave a message at a Place. It appears on the recipient\'s phone when they arrive.',
  );
  String get inbox => t('Masuk', 'Inbox');
  String get sent => t('Terkirim', 'Sent');
  String get newTitipan => t('Titipan baru', 'New Note');
  String get titipanTitle => t('Judul Titipan', 'Note title');
  String get titipanTitleHint =>
      t('Contoh: Jangan lupa kunci pintu', 'e.g. Remember to lock the door');
  String get titipanMessage => t('Pesan', 'Message');
  String get titipanMessageHint => t(
    'Tulis pesan yang ingin mereka baca di sana…',
    'Write what they should read there…',
  );
  String get titipanTrigger => t('Muncul saat', 'Appears when');
  String get titipanRecipient => t('Untuk siapa?', 'Who is it for?');
  String get titipanRecipientHint =>
      t('Nama atau email (opsional)', 'Name or email (optional)');
  String get shareInvite => t('Bagikan undangan', 'Share invite');
  String get copyInvite => t('Salin tautan', 'Copy link');
  String get inviteCopied =>
      t('Tautan undangan disalin.', 'Invite link copied.');
  String get inviteShareText => t(
    'Aku meninggalkan Titipan untukmu di Singgah. Buka tautan ini saat kamu tiba:',
    'I left a Note for you in Singgah. Open this link when you arrive:',
  );
  String get acceptInvite => t('Terima Titipan', 'Accept Note');
  String get acceptingInvite => t('Menerima Titipan…', 'Accepting Note…');
  String get inviteAccepted => t(
    'Titipan diterima. Pesan akan muncul saat kamu tiba.',
    'Note accepted. It will appear when you arrive.',
  );
  String get inviteInvalid => t(
    'Tautan undangan tidak valid atau sudah dipakai.',
    'This invite is invalid or already used.',
  );
  String get inviteLoginFirst => t(
    'Masuk dulu untuk menerima Titipan ini.',
    'Sign in first to accept this Note.',
  );
  String get inviteTitle => t('Undangan Titipan', 'Note invitation');
  String inviteFrom(String name) => t('Dari $name', 'From $name');
  String inviteAt(String place) => t('Di $place', 'At $place');
  String get noInbox => t('Belum ada Titipan masuk.', 'No Notes received yet.');
  String get noInboxBody => t(
    'Saat seseorang mengirim Titipan dan kamu menerima undangannya, pesannya muncul di sini.',
    'When someone sends a Note and you accept the invite, it appears here.',
  );
  String get noSent => t('Belum ada Titipan terkirim.', 'No Notes sent yet.');
  String get noSentBody => t(
    'Tinggalkan pesan untuk keluarga, pasangan, atau rekan di sebuah Titik.',
    'Leave a message for family, a partner, or a colleague at a Place.',
  );
  String get titipanSaved => t('Titipan dibuat.', 'Note created.');
  String get titipanDelete => t('Hapus Titipan?', 'Delete Note?');
  String get titipanDeleteBody => t(
    'Penerima tidak akan bisa membuka Titipan ini lagi.',
    'Recipients will no longer be able to open this Note.',
  );
  String get titipanDeleted => t('Titipan dihapus.', 'Note deleted.');
  String get titipanPending => t('Menunggu diterima', 'Waiting to be accepted');
  String get titipanAccepted => t('Diterima', 'Accepted');
  String get titipanNewBadge => t('Baru', 'New');
  String get titipanRealtime => t('Tersinkron realtime', 'Synced in realtime');
  String get titipanNoRealtime => t(
    'Titipan akan muncul saat perangkat kembali online.',
    'The Note will appear when the device is back online.',
  );
  String get leaveNote => t('Titipkan pesan', 'Leave a Note');
  String titipanFrom(String name) => t('Dari $name', 'From $name');
  String titipanTo(String name) => t('Untuk $name', 'For $name');
  String get markRead => t('Tandai sudah dibaca', 'Mark as read');

  // History
  String get historySubtitle => t(
    'Catatan kapan kamu tiba dan pergi. Hanya tersimpan di perangkat ini.',
    'A record of when you arrived and left. Stored on this device only.',
  );
  String get noHistory => t('Belum ada Singgah.', 'No stops yet.');
  String get noHistoryBody => t(
    'Setelah Misi berbunyi, momen tiba dan pergi akan muncul di sini.',
    'After a Mission fires, arrivals and departures will show up here.',
  );
  String get arrived => t('Tiba', 'Arrived');
  String get left => t('Pergi', 'Left');
  String get clearHistory => t('Bersihkan riwayat', 'Clear history');
  String get clearHistoryConfirm => t(
    'Riwayat Singgah di perangkat ini akan dihapus. Titik dan Misi tidak terpengaruh.',
    'Stop history on this device will be cleared. Places and Missions are not affected.',
  );
  String get historyCleared => t('Riwayat dibersihkan.', 'History cleared.');
  String get historyLocalOnly =>
      t('Tidak diunggah ke cloud', 'Never uploaded to the cloud');
  String get today => t('Hari ini', 'Today');
  String get yesterday => t('Kemarin', 'Yesterday');
  String get thisWeek => t('Minggu ini', 'This week');
  String get older => t('Lebih lama', 'Older');

  // Natural input / AI
  String get naturalTitle => t('Ketik natural', 'Type naturally');
  String get naturalSubtitle => t(
    'Tulis dengan bahasamu sendiri. AI mengubahnya jadi Misi, Titik, dan jadwal — kamu tetap yang menyetujui.',
    'Write in your own words. AI turns it into a Mission, Place, and schedule — you still approve it.',
  );
  String get naturalHint => t(
    'Contoh: ingetin beli galon pas lewat Alfamart dekat rumah',
    'e.g. remind me to buy water when I pass the Alfamart near home',
  );
  String get parseNatural => t('Ubah jadi Misi', 'Turn into a Mission');
  String get parsingNatural =>
      t('Membaca kalimatmu…', 'Reading your sentence…');
  String get naturalReview =>
      t('Periksa sebelum disimpan', 'Review before saving');
  String get naturalReviewBody => t(
    'AI bisa salah. Koreksi judul, Titik, kondisi, atau jadwal di bawah.',
    'AI can be wrong. Correct the title, Place, condition, or schedule below.',
  );
  String get aiUnavailable => t(
    'AI sedang tidak tersedia. Kamu bisa mengisi Misi secara manual.',
    'AI is unavailable. You can fill in the Mission manually.',
  );
  String get tryManual => t('Isi manual', 'Enter manually');
  String get naturalEmpty =>
      t('Tulis dulu kalimatnya.', 'Write a sentence first.');
  String get naturalTooLong => t(
    'Kalimat terlalu panjang (maks. 500 karakter).',
    'Sentence is too long (max 500 characters).',
  );
  String get naturalNoPlace => t(
    'Titik belum dikenali. Pilih atau cari Titik di langkah berikutnya.',
    'Place not recognised. Pick or search a Place in the next step.',
  );
  String naturalConfidence(int percent) =>
      t('Keyakinan AI $percent%', 'AI confidence $percent%');
  String get naturalAiBadge =>
      t('Diproses di server', 'Processed on the server');
  String get naturalRateLimited => t(
    'Batas harian Ketik Natural tercapai. Coba lagi nanti atau isi manual.',
    'Natural input limit reached. Try later or enter it manually.',
  );
  String get naturalSuggestion => t('Saran', 'Suggestion');
  String get naturalMatchedPlace =>
      t('Cocok dengan Titik tersimpan', 'Matches a saved Place');
  String get naturalNewPlace =>
      t('Titik baru akan dibuat', 'A new Place will be created');
  String get naturalPlaceSearch =>
      t('Cari Titik pengganti', 'Find a replacement Place');

  // Settings
  String get appearance => t('Tampilan', 'Appearance');
  String get theme => t('Tema', 'Theme');
  String get themeSystem => t('Ikuti sistem', 'System');
  String get themeLight => t('Terang', 'Light');
  String get themeDark => t('Gelap', 'Dark');
  String get language => t('Bahasa', 'Language');
  String get privacy => t('Privasi', 'Privacy');
  String get privacySettingsBody => t(
    'Singgah menyimpan Titik dan Misi di perangkat. Lokasi real-time tidak pernah dibagikan. Riwayat Singgah tidak diunggah.',
    'Singgah keeps Places and Missions on your device. Real-time location is never shared. Stop history is never uploaded.',
  );
  String get biometricLock => t('Kunci biometrik', 'Biometric lock');
  String get biometricBody => t(
    'Minta sidik jari atau wajah saat membuka aplikasi.',
    'Ask for a fingerprint or face when opening the app.',
  );
  String get biometricUnavailable => t(
    'Biometrik tidak tersedia di perangkat ini.',
    'Biometrics are not available on this device.',
  );
  String get biometricFailed =>
      t('Biometrik tidak dikenali.', 'Biometric not recognised.');
  String get permissions => t('Izin & lokasi', 'Permissions & location');
  String get permissionsBody => t(
    'Lihat status izin lokasi dan notifikasi, lalu buka pengaturan sistem bila perlu.',
    'Check location and notification permissions, then open system settings if needed.',
  );
  String get notifications => t('Notifikasi', 'Notifications');
  String get backgroundLocation =>
      t('Lokasi latar belakang', 'Background location');
  String get foregroundLocation =>
      t('Lokasi saat dipakai', 'Location while in use');
  String get locationServices =>
      t('Layanan lokasi (GPS)', 'Location services (GPS)');
  String get sync => t('Sinkronisasi', 'Sync');
  String get syncNow => t('Sinkron sekarang', 'Sync now');
  String get refresh => t('Muat ulang', 'Refresh');
  String get syncing => t('Menyinkronkan…', 'Syncing…');
  String get synced => t('Tersinkron', 'Synced');
  String get offline => t('Offline', 'Offline');
  String pendingChanges(int count) =>
      t('$count perubahan menunggu', '$count changes pending');
  String lastSync(String when) =>
      t('Terakhir sinkron $when', 'Last synced $when');
  String get neverSynced => t('Belum pernah sinkron', 'Never synced');
  String get syncOfflineBody => t(
    'Perubahan disimpan di perangkat dan dikirim otomatis saat online.',
    'Changes are saved on-device and sent automatically when online.',
  );
  String get about => t('Tentang', 'About');
  String get version => t('Versi', 'Version');
  String get madeFor => t(
    'Dibuat untuk momen yang tepat: saat kamu benar-benar ada di sana.',
    'Built for the right moment: when you are actually there.',
  );
  String get cloudConnected => t('Cloud terhubung', 'Cloud connected');
  String get cloudDemo => t('Penyimpanan lokal (demo)', 'Local storage (demo)');
  String get account => t('Akun', 'Account');
  String get editProfile => t('Ubah profil', 'Edit profile');
  String get profileSaved => t('Profil disimpan.', 'Profile saved.');
  String get avatarChange => t('Ganti foto', 'Change photo');
  String get invalidEmail =>
      t('Format email belum benar.', 'That email format looks off.');
  String get exportData => t('Ekspor data', 'Export data');
  String get exportDataBody => t(
    'Unduh Titik, Misi, dan Titipan sebagai JSON.',
    'Download Places, Missions, and Notes as JSON.',
  );
  String get exportReady => t('File ekspor siap.', 'Export file is ready.');

  // Common
  String get save => t('Simpan', 'Save');
  String get cancel => t('Batal', 'Cancel');
  String get delete => t('Hapus', 'Delete');
  String get edit => t('Ubah', 'Edit');
  String get close => t('Tutup', 'Close');
  String get back => t('Kembali', 'Back');
  String get next => t('Lanjut', 'Next');
  String get continueLabel => t('Lanjut', 'Continue');
  String get retry => t('Coba lagi', 'Try again');
  String get loading => t('Menyiapkan…', 'Getting ready…');
  String get error => t('Ada yang tidak beres.', 'Something went wrong.');
  String get errorLoadData => t('Gagal memuat data.', 'Could not load data.');
  String get errorSaveData => t('Gagal menyimpan.', 'Could not save.');
  String get search => t('Cari', 'Search');
  String get clear => t('Hapus', 'Clear');
  String get add => t('Tambah', 'Add');
  String get done => t('Selesai', 'Done');
  String get confirm => t('Konfirmasi', 'Confirm');
  String get yes => t('Ya', 'Yes');
  String get no => t('Tidak', 'No');
  String get optional => t('Opsional', 'Optional');
  String get required => t('Wajib', 'Required');
  String get all => t('Semua', 'All');
  String get none => t('Tidak ada', 'None');
  String get on => t('Aktif', 'On');
  String get off => t('Mati', 'Off');
  String get notificationReminder => t('Pengingat Singgah', 'Singgah reminder');
  String get notificationTitipan => t('Titipan baru', 'New Note');
  String get notificationChannelDesc => t(
    'Pengingat saat tiba atau meninggalkan Titik',
    'Alerts when arriving at or leaving a Place',
  );
  String get minute => t('menit', 'min');
  String get hour => t('jam', 'hr');
  String get meter => t('m', 'm');
  String get km => t('km', 'km');
  String get now => t('Sekarang', 'Now');
  String get deleteFailed => t('Gagal menghapus.', 'Could not delete.');
  String get noInternet => t('Tidak ada koneksi.', 'No connection.');
  String get notFound => t('Halaman tidak ditemukan.', 'Page not found.');
  String get geofenceNotSupported => t(
    'Geofence tidak tersedia di platform ini.',
    'Geofences are not available on this platform.',
  );
  String locationAccuracy(int meters) =>
      t('Akurasi ±$meters m', 'Accuracy ±$meters m');

  // Status and helper copy
  String get somethingWrong =>
      t('Ada yang tidak beres.', 'Something went wrong.');
  String get tapToRetry => t('Ketuk untuk mencoba lagi.', 'Tap to try again.');
  String get connectionProblem => t('Koneksi bermasalah', 'Connection problem');
  String get statusSynced => t('Tersinkron', 'Synced');
  String get viewAll => t('Lihat semua', 'View all');
  String get seeAll => t('Semua', 'See all');
  String get searching => t('Mencari…', 'Searching…');
  String get noResults => t('Tidak ada hasil.', 'No results.');
  String get tapToSelect => t('Ketuk untuk memilih', 'Tap to select');
  String get selected => t('Dipilih', 'Selected');
  String get changePlace => t('Ganti Titik', 'Change Place');
  String get choosePlace => t('Pilih Titik', 'Choose Place');
  String get useThisPoint => t('Pakai titik ini', 'Use this point');
  String get centerOnMe =>
      t('Pusatkan ke lokasi saya', 'Centre on my location');
  String get mapLoading => t('Memuat peta…', 'Loading map…');
  String get mapUnavailable => t(
    'Peta tidak bisa dimuat. Kamu masih bisa memakai pencarian atau lokasi saat ini.',
    'The map could not load. You can still use search or your current location.',
  );
  String get biometricReason => t('Buka Singgah', 'Unlock Singgah');
  String get locked => t('Terkunci', 'Locked');
  String get unlock => t('Buka dengan biometrik', 'Unlock with biometrics');
  String get biometricSubtitle => t(
    'Kunci biometrik melindungi Titipan dan riwayat di perangkat ini.',
    'Biometric lock protects Notes and history on this device.',
  );
  String get locationReminders => t('Pengingat lokasi', 'Location reminders');
  String get locationRemindersBody => t(
    'Daftarkan geofence untuk Misi dan Titipan yang sudah diterima.',
    'Register geofences for Missions and accepted Notes.',
  );
  String get keepHistoryLabel => t('Simpan riwayat', 'Keep history');
  String get keepHistoryBody => t(
    'Riwayat Singgah hanya tersimpan di perangkat ini.',
    'Stop history stays on this device only.',
  );
  String get defaultRadius => t('Radius bawaan', 'Default radius');
  String get onboardingStart => t('Mulai atur', 'Start setup');
  String get skipForNow => t('Lewati dulu', 'Skip for now');
  String get finishSetup => t('Selesai', 'Finish');
  String get permissionStepLocation =>
      t('Langkah 1 · Izin lokasi', 'Step 1 · Location permission');
  String get permissionStepBackground =>
      t('Langkah 2 · Lokasi sepanjang waktu', 'Step 2 · All-the-time location');
  String get permissionStepNotifications =>
      t('Langkah 3 · Notifikasi', 'Step 3 · Notifications');
  String get permissionReady => t('Siap dipakai', 'Ready to use');
  String get permissionReadyBody => t(
    'Misi dan Titipan bisa berbunyi saat kamu tiba atau pergi.',
    'Missions and Notes can fire when you arrive or leave.',
  );
  String get enableLocationReminders =>
      t('Aktifkan pengingat lokasi', 'Enable location reminders');
  String get disableLocationReminders =>
      t('Jeda pengingat lokasi', 'Pause location reminders');
  String get remindersOff => t(
    'Pengingat lokasi dijeda. Titik dan Misi tetap tersimpan.',
    'Location reminders are paused. Places and Missions are kept.',
  );
  String remindersOn(int count) => t(
    'Pengingat lokasi aktif untuk $count geofence.',
    'Location reminders active for $count geofences.',
  );
  String get noGeofenceYet => t(
    'Belum ada geofence terdaftar. Tambahkan Misi aktif atau terima Titipan.',
    'No geofences registered yet. Add an active Mission or accept a Note.',
  );
  String get missionPlaceLabel => t('Titik', 'Place');
  String get missionScheduleLabel => t('Jadwal', 'Schedule');
  String get missionConditionLabel => t('Kondisi', 'Condition');
  String get missionStatusLabel => t('Status', 'Status');
  String missionLastTriggered(String when) =>
      t('Terakhir berbunyi $when', 'Last fired $when');
  String get missionNeverTriggered =>
      t('Belum pernah berbunyi', 'Never fired yet');
  String get pickTimeStart => t('Jam mulai', 'Start time');
  String get pickTimeEnd => t('Jam selesai', 'End time');
  String get repeatEveryDayShort => t('Setiap hari', 'Every day');
  String get repeatCustom => t('Hari tertentu', 'Specific days');
  String get titipanSender => t('Pengirim', 'Sender');
  String get titipanPlace => t('Titik', 'Place');
  String get titipanWhen => t('Muncul saat', 'Appears when');
  String get titipanStatus => t('Status', 'Status');
  String titipanCreated(String when) => t('Dibuat $when', 'Created $when');
  String get createdAtLabel => t('Dibuat', 'Created');
  String get readBadge => t('Sudah dibaca', 'Read');
  String get unreadBadge => t('Belum dibaca', 'Unread');
  String get share => t('Bagikan', 'Share');
  String get shareFailed => t('Gagal membagikan.', 'Could not share.');
  String get copied => t('Disalin.', 'Copied.');
  String get copy => t('Salin', 'Copy');
  String get openMaps => t('Buka di peta', 'Open in maps');
  String get nearby => t('Terdekat', 'Nearest');
  String distanceAway(String distance) =>
      t('$distance dari sini', '$distance away');
  String get noLocationYet =>
      t('Lokasi belum tersedia', 'Location not available yet');
  String get profileSubtitle => t(
    'Nama dan foto ini tampil untuk penerima Titipanmu.',
    'This name and photo are shown to people who receive your Notes.',
  );
  String get accountCloudBody => t(
    'Titik, Misi, dan Titipan tersinkron lewat Appwrite dengan izin per baris.',
    'Places, Missions, and Notes sync through Appwrite with row-level permissions.',
  );
  String get accountDemoBody => t(
    'Mode demo menyimpan semuanya di perangkat ini saja.',
    'Demo mode keeps everything on this device only.',
  );
  String get inviteNeedsSignIn => t(
    'Masuk atau coba demo dulu, lalu buka tautan undangan lagi.',
    'Sign in or try demo first, then open the invite link again.',
  );
  String get inviteOpen => t('Buka Titipan', 'Open Note');
  String get inviteAlreadyAccepted =>
      t('Titipan ini sudah kamu terima.', 'You already accepted this Note.');
  String get inviteOwner => t(
    'Kamu membuat Titipan ini. Bagikan tautannya ke penerima.',
    'You created this Note. Share the link with a recipient.',
  );
  String get pendingInvite => t('Menunggu', 'Pending');
  String get inviteLink => t('Tautan undangan', 'Invite link');
  String get inviteLinkBody => t(
    'Siapa pun yang membuka tautan ini dan masuk bisa menerima Titipan.',
    'Anyone who opens this link and signs in can accept the Note.',
  );
  String get naturalPlaceTitle =>
      t('Titik untuk Misi ini', 'Place for this Mission');
  String get naturalPlaceSaved =>
      t('Pakai Titik tersimpan', 'Use a saved Place');
  String get naturalPlaceNew => t('Buat Titik baru', 'Create a new Place');
  String get naturalNeedCoords => t(
    'Pilih titik di peta supaya Titik baru punya koordinat.',
    'Pick a point on the map so the new Place has coordinates.',
  );
  String get naturalApprove => t('Setujui & simpan', 'Approve & save');
  String get naturalSaved => t(
    'Misi dari Ketik Natural tersimpan.',
    'Mission from natural input saved.',
  );
  String get naturalManualBody => t(
    'Isi judul, Titik, dan jadwal sendiri. Tidak ada data yang dikirim ke AI.',
    'Fill in the title, Place, and schedule yourself. Nothing is sent to AI.',
  );
  String get aiServerNote => t(
    'Kalimatmu dikirim ke server Singgah, bukan langsung ke penyedia AI. Kunci API tidak ada di aplikasi.',
    'Your sentence goes to the Singgah server, not straight to the AI provider. API keys are not in the app.',
  );
  String get historyPrivacy => t(
    'Riwayat hanya di perangkat ini dan tidak pernah diunggah.',
    'History stays on this device and is never uploaded.',
  );
  String get allMissionsPausedShort =>
      t('Semua Misi dijeda', 'All Missions paused');
  String get resumeAll => t('Aktifkan kembali', 'Resume all');
  String get deleteAccountData => t('Hapus data lokal', 'Clear local data');
  String get deleteAccountDataBody => t(
    'Menghapus Titik, Misi, Titipan, dan riwayat dari perangkat ini. Data cloud tidak terhapus.',
    'Removes Places, Missions, Notes, and history from this device. Cloud data is not deleted.',
  );
  String get dataCleared => t('Data lokal dibersihkan.', 'Local data cleared.');
  String radiusValue(int meters) => t('$meters m', '$meters m');
  String get searchPoweredBy => t(
    'Pencarian lewat server Singgah · OpenStreetMap',
    'Search via the Singgah server · OpenStreetMap',
  );

  // Weekday short names (index 1..7, Monday first).
  List<String> get weekdayShort => isId
      ? const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
      : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String weekday(int weekday) => weekdayShort[(weekday - 1).clamp(0, 6)];

  String daysLabel(Set<int> days) {
    if (days.isEmpty || days.length == 7) return everyDay;
    final sorted = days.toList()..sort();
    return sorted.map(weekday).join(' · ');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
