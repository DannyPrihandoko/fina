import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
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
                  _buildProfileHeader(context, ref),
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
                  _buildSectionLabel(context, 'NOTIFIKASI'),
                  const SizedBox(height: 16),
                  _buildSettingsGroup(
                    context,
                    [
                      _buildSwitchItem(
                        context,
                        icon: Icons.notifications_active_rounded,
                        iconColor: Theme.of(context).colorScheme.secondary,
                        title: 'Aktifkan Notifikasi',
                        subtitle: 'Terima pengingat tagihan harian',
                        value: notificationsEnabled,
                        onChanged: (value) => _toggleNotifications(ref, context, value),
                      ),
                      if (notificationsEnabled) ...[
                        _buildSettingsItem(
                          context,
                          icon: Icons.send_rounded,
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: 'Tes Notifikasi',
                          onTap: () async {
                            try {
                              await NotificationService().showTestNotification();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal mengirim notifikasi: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildSectionLabel(context, 'UMUM'),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
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
          GestureDetector(
            onTap: () => _pickImage(ref),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor, width: 2),
                image: settings.profilePhotoPath != null
                    ? DecorationImage(
                        image: FileImage(File(settings.profilePhotoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: settings.profilePhotoPath == null
                  ? Icon(Icons.person_rounded, color: Theme.of(context).textTheme.bodyLarge?.color, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.userName,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'FINA PREMIUM',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editName(ref, context, settings.userName),
            icon: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
            color: Theme.of(context).dividerColor.withOpacity(0.1),
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
            Text(trailingText, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).dividerColor, size: 20),
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
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      trailing: Switch.adaptive(
        value: value,
        activeColor: Theme.of(context).colorScheme.secondary,
        onChanged: onChanged,
      ),
    );
  }
}
