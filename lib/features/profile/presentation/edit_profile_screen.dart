import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/textured_background.dart';
import '../../auth/application/auth_controller.dart';
import 'avatar_position_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  String? _avatarPath;
  String _country = 'Indonesia';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;

    final nameParts = (user?.fullName ?? '').trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final combinedName =
        last.isNotEmpty ? '$first $last' : first;

    final updated = currentUser.copyWith(
      fullName: combinedName.isNotEmpty ? combinedName : currentUser.fullName,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      birthDate: parsedDob,
      address: _country,
      photoUrl: _avatarPath,
    );

    final success =
        await ref.read(authControllerProvider.notifier).updateProfile(updated);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan perubahan profil.')),
      );
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppColors.textPrimary),
              title: const Text('Kamera',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.textPrimary),
              title: const Text('Galeri',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profil Pengguna',
          style: AppTypography.headingMd.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    // Large Avatar with Camera Icon Badge
                    Center(
                      child: _UserAvatar(
                        avatarPath: _avatarPath,
                        onTap: _pickAvatar,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _RoundedField(
                      label: 'Nama Depan',
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RoundedField(
                      label: 'Nama Belakang',
                      controller: _lastNameController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RoundedField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RoundedField(
                      label: 'Nomor Telepon',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RoundedField(
                      label: 'Tanggal Lahir',
                      controller: _birthDateController,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      trailingIcon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CountryDropdown(
                      value: _country,
                      onChanged: (val) => setState(() => _country = val),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
              // Save Button at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: AppButton(
                  label: 'SIMPAN',
                  expand: true,
                  isLoading: isUpdating,
                  background: AppColors.accentSoft,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.avatarPath, required this.onTap});

  final String? avatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentSoft.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatarImage(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: AppColors.accentSoft,
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
        return Image.file(file, fit: BoxFit.cover);
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

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.trailingIcon,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTypography.bodySm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            suffixIcon: trailingIcon != null
                ? Icon(trailingIcon, size: 20, color: AppColors.textTertiary)
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.accentSoft, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _countries = ['Indonesia', 'Singapura', 'Malaysia', 'Australia'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Kota/Negara',
            style: AppTypography.bodySm.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: AppColors.textPrimary),
              style: AppTypography.bodySm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
