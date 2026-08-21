import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'avatar_position_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/textured_background.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/theme/app_elevation.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _birthDateController;
  String? _avatarPath;

  String _country = 'Indonesia';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController(text: '••••••••••••••••');
    _birthDateController = TextEditingController(
      text: user?.birthDate == null
          ? ''
          : DateFormat('dd/MM/yyyy').format(user!.birthDate!),
    );
    _avatarPath = user?.photoUrl;
    if (user?.address != null && user!.address!.isNotEmpty) {
      _country = user.address!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser == null) return;

    DateTime? parsedDob;
    if (_birthDateController.text.isNotEmpty) {
      try {
        parsedDob = DateFormat('dd/MM/yyyy').parse(_birthDateController.text);
      } catch (_) {}
    }

    final updated = currentUser.copyWith(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      birthDate: parsedDob,
      address: _country,
      photoUrl: _avatarPath,
    );

    final success =
        await ref.read(authControllerProvider.notifier).updateProfile(updated);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan profil berhasil disimpan.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan perubahan profil.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Profil',
                      textAlign: TextAlign.center,
                      style: AppTypography.headingLg.copyWith(
                        fontSize: 32,
                        color: AppColors.accentSoft,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Keluar',
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).signOut();
                      context.go(AppRoutes.onboarding);
                    },
                    icon: const Icon(Icons.logout),
                    color: AppColors.accentSoft,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: _AvatarPicker(
                  avatarPath: _avatarPath,
                  onTap: _pickAvatar,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _ProfileField(label: 'Nama', controller: _nameController),
              _ProfileField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _ProfileField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
              ),
              _ProfileField(
                label: 'Tanggal Lahir',
                controller: _birthDateController,
                readOnly: true,
                trailingIcon: Icons.expand_more,
                onTap: _pickBirthDate,
              ),
              _CountryField(
                value: _country,
                onChanged: (value) => setState(() => _country = value),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: AppButton(
                  label: 'Simpan',
                  background: AppColors.accentSoft,
                  isLoading: ref.watch(authControllerProvider).isLoading,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.textPrimary),
              title: const Text('Kamera', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.textPrimary),
              title: const Text('Galeri', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        final croppedPath = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => AvatarPositionScreen(
              imageFile: File(pickedFile.path),
            ),
          ),
        );

        if (croppedPath != null && mounted) {
          setState(() {
            _avatarPath = croppedPath;
          });
        }
      }
    }
  }
}

/// Circular avatar with the camera badge from the design.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({this.avatarPath, required this.onTap});

  final String? avatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 122,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.border,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatarImage(),
          ),
          Positioned(
            right: -4,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppElevation.level2,
              ),
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('changeAvatar'),
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.photo_camera,
                      size: 21,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      final file = File(avatarPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      } else if (avatarPath!.startsWith('http')) {
        return Image.network(
          avatarPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultIcon(),
        );
      }
    }
    return Image.asset(
      'assets/images/avatar.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _defaultIcon(),
    );
  }

  Widget _defaultIcon() {
    return const Icon(
      Icons.person,
      size: 60,
      color: AppColors.textTertiary,
    );
  }
}

/// A labelled dark field, as used throughout the profile form.
class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.trailingIcon,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.headingSm.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accentSoft,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            onTap: onTap,
            style: AppTypography.bodySm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xB3DDDFF3),
            ),
            cursorColor: AppColors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.accentSoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              suffixIcon: trailingIcon == null
                  ? null
                  : Icon(trailingIcon, color: AppColors.white, size: 22),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border({double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.xs),
    borderSide: BorderSide(color: const Color(0x59000000), width: width),
  );
}

/// The country row, which is a dropdown rather than free text.
class _CountryField extends StatelessWidget {
  const _CountryField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _countries = ['Indonesia', 'Singapura', 'Malaysia', 'Australia'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kota/Negara',
          style: AppTypography.headingSm.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: const Color(0x59000000)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.accentSoft,
              icon: const Icon(Icons.expand_more, color: AppColors.white),
              style: AppTypography.bodySm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xB3DDDFF3),
              ),
              items: [
                for (final country in _countries)
                  DropdownMenuItem(value: country, child: Text(country)),
              ],
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }
}
