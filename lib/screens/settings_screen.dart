import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    // For now, we assume it's disabled until requested
    // In a real app, you'd check storage or permission status
    setState(() {
      _notificationsEnabled = false; 
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermissions();
      if (granted) {
        setState(() => _notificationsEnabled = true);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifikasi diaktifkan!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin notifikasi ditolak.')),
          );
        }
        setState(() => _notificationsEnabled = false);
      }
    } else {
      setState(() => _notificationsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      value: _notificationsEnabled,
                      activeColor: AppColors.ctaAqua,
                      onChanged: _toggleNotifications,
                    ),
                  ),
                  if (_notificationsEnabled) ...[
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
