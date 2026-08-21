import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Where the patient goes after a booking is created.
enum BookingSuccessAction { viewHistory, home }

/// The confirmation sheet shown once the booking has been created.
class BookingSuccessSheet extends StatelessWidget {
  const BookingSuccessSheet({super.key, required this.bookingCode});

  final String bookingCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFDDDFF3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SuccessMark(size: 96),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Janji Temu Berhasil Dibuat!',
              textAlign: TextAlign.center,
              style: AppTypography.headingSm.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Booking ID: $bookingCode',
              textAlign: TextAlign.center,
              style: AppTypography.headingSm.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accentSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Anda akan mendapatkan Booking ID & QR code untuk dipakai saat '
              'check in. Silahkan klik tombol Lihat Riwayat Janji Temu untuk '
              'detail lebih lanjut.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(fontSize: 14, height: 1.25),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Kuitansi untuk Biaya Berobat akan Anda dapatkan di Counter RS.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(fontSize: 14, height: 1.25),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _Action(
              key: const Key('successHistory'),
              label: 'Lihat Riwayat Janji Temu',
              background: const Color(0xFFFFF9F9),
              foreground: AppColors.textPrimary,
              onTap: () =>
                  Navigator.of(context).pop(BookingSuccessAction.viewHistory),
            ),
            const SizedBox(height: AppSpacing.md),
            _Action(
              key: const Key('successHome'),
              label: 'Beranda',
              background: AppColors.accentSoft,
              foreground: const Color(0xFFDDDFF3),
              onTap: () => Navigator.of(context).pop(BookingSuccessAction.home),
            ),
          ],
        ),
      ),
    );
  }
}

/// A filled circle with a tick — drawn rather than shipped as an image.
class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.link,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, size: size * 0.55, color: AppColors.white),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Container(
          width: double.infinity,
          height: 53,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(
              color: background == AppColors.accentSoft
                  ? const Color(0xFFDDDFF3)
                  : AppColors.textPrimary,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
