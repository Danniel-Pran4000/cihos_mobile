import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/textured_background.dart';
import '../../auth/application/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/faq_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _pushNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final fullName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Pengguna';
    final photoUrl = user?.photoUrl;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xxxl,
            ),
            children: [
              // Screen Title
              Text(
                'Profil',
                style: AppTypography.headingLg.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // User Info Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentSoft.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    // Avatar Thumbnail
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildAvatar(photoUrl),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMd.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Keluar Akun',
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.accentSoft,
                        size: 22,
                      ),
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).signOut();
                        context.go(AppRoutes.onboarding);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Settings Options List
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profil Pengguna',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Ubah Kata Sandi',
                onTap: () => ChangePasswordSheet.show(context),
              ),
              const SizedBox(height: AppSpacing.md),

              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Tanya Jawab (FAQ)',
                onTap: () => FaqSheet.show(context),
              ),
              const SizedBox(height: AppSpacing.md),

              _SettingsSwitchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi Aplikasi',
                value: _pushNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _pushNotificationsEnabled = val);
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // WhatsApp / Query Card at the bottom
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF5F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Punya pertanyaan atau butuh bantuan lebih lanjut? Hubungi kami.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Menghubungi Layanan Bantuan Ciputra Hospital...',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          'Hubungi via WhatsApp',
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      } else if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.person,
            size: 28,
            color: AppColors.textTertiary,
          ),
        );
      }
    }
    return Image.asset(
      'assets/images/avatar.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.person,
        size: 28,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFFB9E4C9),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
