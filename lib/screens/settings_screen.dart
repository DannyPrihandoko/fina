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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).appBarTheme.titleTextStyle?.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).appBarTheme.titleTextStyle?.color)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 24, right: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Profile Header (Excluvise Look)
                  _buildProfileHeader(context),
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
                  _buildSectionLabel('NOTIFIKASI'),
                  const SizedBox(height: 16),
                  _buildSettingsGroup(
                    context,
                    [
                      _buildSwitchItem(
                        context,
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppColors.ctaAqua,
                        title: 'Aktifkan Notifikasi',
                        subtitle: 'Terima pengingat tagihan harian',
                        value: notificationsEnabled,
                        onChanged: (value) => _toggleNotifications(ref, context, value),
                      ),
                      if (notificationsEnabled) ...[
                        _buildSettingsItem(
                          context,
                          icon: Icons.send_rounded,
                          iconColor: AppColors.primary,
                          title: 'Tes Notifikasi',
                          onTap: () => NotificationService().showTestNotification(),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildSectionLabel('UMUM'),
                  const SizedBox(height: 16),
                  _buildSettingsGroup(
                    context,
                    [
                    _buildSettingsItem(
                      context,
                      icon: Icons.language_rounded,
                      iconColor: Colors.blue,
                      title: 'Bahasa',
                      trailingText: 'Indonesia',
                    ),
                    _buildSwitchItem(
                      context,
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.deepPurple,
                      title: 'Mode Gelap',
                      subtitle: 'Aktifkan tema gelap yang elegan',
                      value: settings.isDarkMode,
                      onChanged: (value) => ref.read(settingsProvider.notifier).setDarkMode(value),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.verified_user_rounded,
                      iconColor: Colors.teal,
                      title: 'Keamanan (Biometrik)',
                      trailingText: 'Nonaktif',
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_rounded,
                      iconColor: Colors.orange,
                      title: 'Tentang Fina',
                      trailingText: 'v1.0.0',
                    ),
                  ]),

                  const SizedBox(height: 60),
                  Center(
                    child: Text(
                      'FINA APP • MADE WITH LOVE',
                      style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
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

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.textDarkBlue).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor, width: 2),
            ),
            child: Icon(Icons.person_rounded, color: Theme.of(context).textTheme.bodyLarge?.color, size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Fina',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ctaAqua,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FINA PREMIUM',
                    style: TextStyle(color: AppColors.textDarkBlue, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.edit_note_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.black : AppColors.borderColor).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText, style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkBorder : AppColors.borderColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.ctaAqua,
        onChanged: onChanged,
      ),
    );
  }
}
