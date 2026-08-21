import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/illustrations.dart';

/// The booked-appointment card under "Konsultasi Anda", carrying the check-in
/// QR code box which opens the QR dialog on tap.
class ConsultationCard extends StatelessWidget {
  const ConsultationCard({
    super.key,
    required this.patientName,
    required this.scheduledAt,
    required this.endsAt,
    required this.bookingCode,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    this.onDetailTap,
  });

  final String patientName;
  final DateTime scheduledAt;
  final DateTime endsAt;
  final String bookingCode;
  final String doctorName;
  final String specialty;
  final String hospital;
  final VoidCallback? onDetailTap;

  void _showQrDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _QrDialog(code: bookingCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentSoft.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Name Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F1FC),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  patientName,
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Schedule Info + QR Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Field(
                      label: 'Jadwal Janji Temu',
                      value: dayFormat.format(scheduledAt),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      label: 'Perkiraan Waktu',
                      value:
                          '${timeFormat.format(scheduledAt)} - ${timeFormat.format(endsAt)} WIB',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      label: 'Kode Booking',
                      value: bookingCode,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Simplified clean QR Panel (Only QR + KLIK DISINI)
              _QrPanel(
                onTap: () => _showQrDialog(context),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Doctor & Hospital
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 18,
                color: AppColors.accentSoft,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$specialty • $hospital',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Bottom Action
          if (onDetailTap != null)
            InkWell(
              onTap: onDetailTap,
              child: Row(
                children: [
                  Text(
                    'Lihat Detail',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSoft,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.accentSoft,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// The clean QR panel showing only QR and "KLIK DISINI".
class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentSoft.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // White QR background box
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Illustrations.qrCode(size: 72),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

/// The detailed full QR dialog that appears when clicking the QR box.
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
