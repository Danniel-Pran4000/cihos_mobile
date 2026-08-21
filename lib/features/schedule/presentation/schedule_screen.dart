import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/textured_background.dart';
import '../../auth/application/auth_controller.dart';
import '../data/schedule_repository.dart';
import '../domain/scheduled_appointment.dart';

/// Upcoming appointments with layout matching History & Profile screens.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  ScheduleFilter _filter = ScheduleFilter.all;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(scheduledAppointmentsProvider);
    final user = ref.watch(authControllerProvider).user;
    final photoUrl = user?.photoUrl;

    final visible = all.where((a) => switch (_filter) {
      ScheduleFilter.all => true,
      ScheduleFilter.self => a.isSelf,
      ScheduleFilter.others => !a.isSelf,
    }).toList();

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID')
        .format(DateTime.now())
        .toUpperCase();

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.appointments),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section (Eyebrow date, Title 'Jadwal Temu', and User Avatar)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayFormatted,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jadwal Temu',
                          style: AppTypography.headingLg.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        // User Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border:
                                Border.all(color: AppColors.border, width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildAvatar(photoUrl),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Bar (Semua / Saya Sendiri / Orang Lain)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: _FilterBar(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Sub-header count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${visible.length} Jadwal Mendatang',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go(AppRoutes.history),
                      child: Row(
                        children: [
                          Text(
                            'Riwayat',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Appointments List
              Expanded(
                child: visible.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.sm,
                          AppSpacing.xxl,
                          AppSpacing.xxxl,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) =>
                            _AppointmentCard(appointment: visible[index]),
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
            size: 22,
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
        size: 22,
        color: AppColors.textTertiary,
      ),
    );
  }
}

/// Segmented filter control with clean animations and consistent size.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final ScheduleFilter selected;
  final ValueChanged<ScheduleFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth =
              constraints.maxWidth / ScheduleFilter.values.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: segmentWidth * selected.index,
                width: segmentWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentSoft.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in ScheduleFilter.values)
                    Expanded(
                      child: InkWell(
                        onTap: () => onChanged(option),
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Text(
                            option.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: option == selected
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Richly styled appointment card with vibrant accent chips and clean layout.
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final ScheduledAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final isBPJS = appointment.guaranteeType.toLowerCase().contains('bpjs');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentSoft.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient row with avatar and patient badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appointment.isSelf
                      ? const Color(0xFFE8F1FC)
                      : const Color(0xFFFFF0DC),
                ),
                child: Icon(
                  appointment.isSelf
                      ? Icons.person_rounded
                      : Icons.family_restroom_rounded,
                  size: 20,
                  color: appointment.isSelf
                      ? AppColors.primary
                      : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      appointment.isSelf ? 'Pasien Utama' : 'Keluarga',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Consultation tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F4F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'JANJI TEMU 1',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Booking Code & Guarantee Type Chips
          Row(
            children: [
              Expanded(
                child: _DetailBox(
                  icon: Icons.confirmation_number_outlined,
                  iconColor: AppColors.primary,
                  label: 'KODE BOOKING',
                  value: appointment.bookingCode,
                  backgroundColor: const Color(0xFFF5F7FB),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailBox(
                  icon: Icons.verified_user_outlined,
                  iconColor: isBPJS
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1),
                  label: 'JENIS JAMINAN',
                  value: appointment.guaranteeType,
                  backgroundColor: isBPJS
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEEF2FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Doctor & Specialty
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                size: 20,
                color: AppColors.accentSoft,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      appointment.specialty,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Date & Time Banner Box
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: AppColors.accentSoft,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                        .format(appointment.startsAt),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textTertiary,
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: AppColors.accentSoft,
                ),
                const SizedBox(width: 4),
                Text(
                  appointment.timeRange,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action Buttons: "Lihat Detail" & "QR Janji Temu"
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                        color: AppColors.accentSoft, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push(
                    '${AppRoutes.appointments}/${appointment.id}',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lihat Detail',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentSoft,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.accentSoft,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSoft,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _QrDialog(code: appointment.bookingCode),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_rounded,
                        size: 17,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'QR Janji Temu',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrDialog extends StatelessWidget {
  const _QrDialog({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR Pendaftaran',
              style: AppTypography.headingMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Illustrations.qrCode(size: 200),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              code,
              style: AppTypography.headingSm.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tunjukkan QR ini pada petugas atau scanner di KiosK pendaftaran.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Illustrations.emptySchedule(size: 160),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tidak ada jadwal temu mendatang',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.accentSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih dokter dan buat janji temu melalui beranda.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
