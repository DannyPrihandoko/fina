import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/database_service.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../widgets/success_modal.dart';
import '../widgets/settings_tiles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleNotifications(
      WidgetRef ref, BuildContext context, bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermissions();
      if (granted) {
        await ref.read(settingsProvider.notifier).setNotificationsEnabled(true);
        if (context.mounted) {
          SuccessModal.show(
            context: context,
            title: 'Notifikasi Aktif!',
            subtitle: 'Anda akan menerima pengingat tagihan dan alert keuangan.',
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin notifikasi ditolak.')),
          );
        }
        await ref
            .read(settingsProvider.notifier)
            .setNotificationsEnabled(false);
      }
    } else {
      await ref.read(settingsProvider.notifier).setNotificationsEnabled(false);
    }
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await ref.read(settingsProvider.notifier).setProfilePhoto(image.path);
    }
  }

  void _editName(WidgetRef ref, BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Profil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Masukkan nama Anda'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(settingsProvider.notifier).setUserName(newName);
                Navigator.pop(context);
                SuccessModal.show(
                  context: context,
                  title: 'Nama Diperbarui!',
                  subtitle: 'Nama profil Anda telah berhasil diubah menjadi $newName.',
                );
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle(WidgetRef ref, BuildContext context) async {
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (!context.mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login dibatalkan.')),
        );
        return;
      }

      // Check if cloud has data
      final hasCloud = await CloudSyncService().isCloudDataAvailable(user.uid);
      if (!context.mounted) return;
      if (hasCloud) {
        final shouldRestore = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Data Cloud Ditemukan',
                style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text(
              'Kami menemukan data tersimpan di cloud milik akun ini.\n\n'
              'Apakah kamu ingin memulihkan data cloud? Data lokal saat ini akan diganti.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('BIARKAN LOKAL'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('PULIHKAN CLOUD'),
              ),
            ],
          ),
        );

        if (shouldRestore == true && context.mounted) {
          await _restoreFromCloud(ref, context, user.uid);
        }
      } else {
        // No cloud data: push local data to cloud
        await _backupNow(ref, context, silent: true);
        if (context.mounted) {
          SuccessModal.show(
            context: context,
            title: 'Login Berhasil!',
            subtitle: 'Akun Google terhubung dan data lokal telah aman disimpan ke cloud.',
          );
        }
      }
    } on AuthServiceException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Google gagal. Coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar dari Akun?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
            'Data kamu tetap tersimpan di cloud. Kamu bisa login kembali kapan saja untuk memulihkannya.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('BATAL')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('KELUAR')),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
    }
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'id':
      default:
        return 'Indonesia';
    }
  }

  Future<void> _showLanguageSelector(
      WidgetRef ref, BuildContext context) async {
    final currentCode = ref.read(settingsProvider).languageCode;
    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Bahasa',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilihan ini disimpan untuk preferensi aplikasi.',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption(
                context,
                code: 'id',
                label: 'Indonesia',
                description: 'Format dan teks utama Bahasa Indonesia',
                selected: currentCode == 'id',
              ),
              const SizedBox(height: 10),
              _buildLanguageOption(
                context,
                code: 'en',
                label: 'English',
                description: 'English preference for future localization',
                selected: currentCode == 'en',
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedCode == null || selectedCode == currentCode) return;
    await ref.read(settingsProvider.notifier).setLanguageCode(selectedCode);
    if (context.mounted) {
      SuccessModal.show(
        context: context,
        title: 'Bahasa Diubah!',
        subtitle: 'Aplikasi sekarang menggunakan ${_languageLabel(selectedCode)}.',
      );
    }
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String code,
    required String label,
    required String description,
    required bool selected,
  }) {
    return ListTile(
      onTap: () => Navigator.pop(context, code),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
          : null,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.16)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          selected ? Icons.check_rounded : Icons.translate_rounded,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(description,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    );
  }

  void _showBiometricInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keamanan Biometrik',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Kunci biometrik belum aktif di build ini karena aplikasi belum memasang modul autentikasi perangkat.\n\n'
          'Data keuangan tetap tersimpan lokal di perangkat. Untuk perlindungan saat ini, gunakan kunci layar ponsel dan backup cloud hanya di akun Google pribadi.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('MENGERTI'),
          ),
        ],
      ),
    );
  }

  void _showAboutFina(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FINA',
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/icon/logo_apps.png', width: 48, height: 48),
      ),
      children: const [
        SizedBox(height: 12),
        Text(
          'FINA membantu mencatat arus kas, mengelola dompet, target finansial, tagihan, insight AI, OCR struk, dan berbagi rekap keuangan secara aman.',
        ),
      ],
    );
  }

  Future<void> _backupNow(WidgetRef ref, BuildContext context,
      {bool silent = false}) async {
    final user = AuthService().currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final db = DatabaseService.instance;
      final settings = ref.read(settingsProvider);
      await CloudSyncService().backupAll(
        uid: user.uid,
        transactions: await db.getAllTransactions(),
        wallets: await db.getAllWallets(),
        bills: await db.getAllBills(),
        budgets: await db.getAllBudgets(),
        goals: await db.getAllGoals(),
        userName: settings.userName,
        photoUrl: user.photoURL,
      );
      if (!silent && context.mounted) {
        SuccessModal.show(
          context: context,
          title: 'Backup Berhasil!',
          subtitle: 'Seluruh data Anda telah aman dicadangkan ke Google Cloud.',
        );
      }
    } catch (e) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Backup gagal: $e')),
        );
      }
    }
  }

  Future<void> _restoreFromCloud(
      WidgetRef ref, BuildContext context, String uid) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await CloudSyncService().restoreAll(uid);
      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Gagal memulihkan data dari cloud.')),
        );
        return;
      }

      final db = DatabaseService.instance;
      final database = await db.database;

      // Wipe local tables
      await database.delete('transactions');
      await database.delete('wallets');
      await database.delete('bills');
      await database.delete('budgets');
      await database.delete('financial_goals');

      // Re-insert from cloud
      for (final w in result.wallets) {
        await db.createWallet(w);
      }
      for (final t in result.transactions) {
        await db.createTransaction(t);
      }
      for (final b in result.bills) {
        await db.createBill(b);
      }
      for (final bg in result.budgets) {
        await db.saveBudget(bg);
      }
      for (final g in result.goals) {
        await db.createGoal(g);
      }

      // Refresh all providers
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(billsProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(goalsProvider);

      if (context.mounted) {
        SuccessModal.show(
          context: context,
          title: 'Restore Berhasil!',
          subtitle: 'Data dari cloud telah dipulihkan. ${result.transactions.length} transaksi dan ${result.wallets.length} dompet siap digunakan.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Restore gagal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notificationsEnabled = settings.isNotificationsEnabled;
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.valueOrNull;
    final isGoogleSignedIn = currentUser != null && !(currentUser.isAnonymous);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).appBarTheme.titleTextStyle?.color,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pengaturan',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).appBarTheme.titleTextStyle?.color)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildProfileHeader(
                      context, ref, isGoogleSignedIn, currentUser),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── AKUN & DATA Section ───────────────────────────────
                  const SectionLabel(label: 'AKUN & DATA'),
                  const SizedBox(height: 16),
                  SettingsGroup(children: [
                    if (!isGoogleSignedIn) ...[
                      GoogleSignInButton(
                        onTap: () => _signInWithGoogle(ref, context),
                      ),
                    ] else ...[
                      SettingsItem(
                        icon: Icons.cloud_upload_rounded,
                        iconColor: Colors.blue,
                        title: 'Backup ke Cloud',
                        subtitle: 'Simpan semua data ke Google Cloud',
                        onTap: () => _backupNow(ref, context),
                      ),
                      SettingsItem(
                        icon: Icons.cloud_download_rounded,
                        iconColor: Colors.green,
                        title: 'Pulihkan dari Cloud',
                        subtitle: 'Ganti data lokal dengan data cloud',
                        onTap: () async {
                          final user = AuthService().currentUser;
                          if (user != null) {
                            await _restoreFromCloud(ref, context, user.uid);
                          }
                        },
                      ),
                      LastSyncTile(uid: currentUser.uid),
                      SettingsItem(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        title: 'Keluar dari Akun Google',
                        onTap: () => _signOut(ref, context),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 32),

                  const SectionLabel(label: 'NOTIFIKASI'),
                  const SizedBox(height: 16),
                  SettingsGroup(
                    children: [
                      SwitchItem(
                        icon: Icons.notifications_active_rounded,
                        iconColor: Theme.of(context).colorScheme.secondary,
                        title: 'Aktifkan Notifikasi',
                        subtitle: 'Terima pengingat tagihan harian',
                        value: notificationsEnabled,
                        onChanged: (value) =>
                            _toggleNotifications(ref, context, value),
                      ),
                      SwitchItem(
                        icon: Icons.auto_graph_rounded,
                        iconColor: Colors.amber,
                        title: 'Smart Alerts',
                        subtitle: 'Notifikasi pengeluaran melebihi bulan lalu',
                        value: settings.isSmartAlertsEnabled,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setSmartAlertsEnabled(value),
                      ),
                      if (notificationsEnabled) ...[
                        SettingsItem(
                          icon: Icons.send_rounded,
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: 'Tes Notifikasi',
                          onTap: () async {
                            try {
                              await NotificationService()
                                  .showTestNotification();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Gagal mengirim notifikasi: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  const SectionLabel(label: 'UMUM'),
                  const SizedBox(height: 16),
                  SettingsGroup(children: [
                    SettingsItem(
                      icon: Icons.language_rounded,
                      iconColor: Colors.blue,
                      title: 'Bahasa',
                      trailingText: _languageLabel(settings.languageCode),
                      onTap: () => _showLanguageSelector(ref, context),
                    ),
                    SwitchItem(
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.deepPurple,
                      title: 'Mode Gelap',
                      subtitle: 'Aktifkan tema gelap yang elegan',
                      value: settings.isDarkMode,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setDarkMode(value),
                    ),
                    SettingsItem(
                      icon: Icons.verified_user_rounded,
                      iconColor: Colors.teal,
                      title: 'Keamanan (Biometrik)',
                      trailingText: 'Nonaktif',
                      onTap: () => _showBiometricInfo(context),
                    ),
                    SettingsItem(
                      icon: Icons.info_rounded,
                      iconColor: Colors.orange,
                      title: 'Tentang Fina',
                      trailingText: 'v1.0.0',
                      onTap: () => _showAboutFina(context),
                    ),
                  ]),

                  const SizedBox(height: 60),
                  Center(
                    child: Text(
                      'FINA APP • MADE WITH LOVE',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, WidgetRef ref, bool isGoogleSignedIn, user) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String displayName = isGoogleSignedIn
        ? (user?.displayName ?? settings.userName)
        : settings.userName;
    final String? photoUrl = isGoogleSignedIn ? user?.photoURL : null;
    final String? localPhoto =
        isGoogleSignedIn ? null : settings.profilePhotoPath;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.textDarkBlue)
                .withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isGoogleSignedIn ? null : () => _pickImage(ref),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.borderColor,
                    width: 2),
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl), fit: BoxFit.cover)
                    : localPhoto != null
                        ? DecorationImage(
                            image: FileImage(File(localPhoto)),
                            fit: BoxFit.cover)
                        : null,
              ),
              child: (photoUrl == null && localPhoto == null)
                  ? Icon(
                      isGoogleSignedIn
                          ? Icons.account_circle_rounded
                          : Icons.person_rounded,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (isGoogleSignedIn) ...[
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_done_rounded,
                                size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Cloud Aktif',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FINA PREMIUM',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isGoogleSignedIn)
            IconButton(
              onPressed: () => _editName(ref, context, settings.userName),
              icon: Icon(Icons.edit_note_rounded,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 28),
            ),
        ],
      ),
    );
  }
}
