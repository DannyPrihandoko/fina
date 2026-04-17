import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../services/notification_service.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleNotifications(WidgetRef ref, BuildContext context, bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermissions();
      if (granted) {
        await ref.read(settingsProvider.notifier).setNotificationsEnabled(true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifikasi diaktifkan!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin notifikasi ditolak.')),
          );
        }
        await ref.read(settingsProvider.notifier).setNotificationsEnabled(false);
      }
    } else {
      await ref.read(settingsProvider.notifier).setNotificationsEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notificationsEnabled = settings.isNotificationsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOTIFIKASI',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardPaleBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.textDarkBlue),
                    ),
                    title: const Text('Aktifkan Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Terima pengingat tagihan dan ringkasan harian'),
                    trailing: Switch.adaptive(
                      value: notificationsEnabled,
                      activeColor: AppColors.ctaAqua,
                      onChanged: (value) => _toggleNotifications(ref, context, value),
                    ),
                  ),
                  if (notificationsEnabled) ...[
                    const Divider(height: 1, indent: 70),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardPaleBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_outlined, color: AppColors.textDarkBlue),
                      ),
                      title: const Text('Tes Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => NotificationService().showTestNotification(),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'UMUM',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.language_outlined,
                    title: 'Bahasa',
                    value: 'Indonesia',
                  ),
                  const Divider(height: 1, indent: 70),
                  _buildSettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Mode Gelap',
                    value: 'Sistem',
                  ),
                  const Divider(height: 1, indent: 70),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'Tentang Fina',
                    value: 'v1.0.0',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, required String value}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardPaleBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textDarkBlue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
      onTap: () {},
    );
  }
}
