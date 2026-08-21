import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../domain/booking.dart';
import '../widgets/booking_success_sheet.dart';
import '../widgets/edit_booking_sheet.dart';
import '../../../core/theme/app_motion.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/booking_repository.dart';

/// Final review before the booking is created.
class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  bool _agreedToTerms = false;
  bool _isExpanded = true;
  bool _isSubmitting = false;

  Future<void> _edit() async {
    final choice = await showModalBottomSheet<EditBookingChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditBookingSheet(),
    );

    if (choice == null || !mounted) return;

    // Each choice rewinds to the step that owns that piece of the booking.
    switch (choice) {
      case EditBookingChoice.doctor:
        context.go(AppRoutes.doctors);
      case EditBookingChoice.schedule:
        context.pop();
        context.pop();
      case EditBookingChoice.patient:
        context.pop();
    }
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setujui Syarat & Ketentuan untuk melanjutkan.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final bookingCode = await ref.read(bookingRepositoryProvider).create(widget.booking);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final destination = await showModalBottomSheet<BookingSuccessAction>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        // Without this the sheet is capped at half the screen, which clips the
        // success mark and the two actions below it.
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BookingSuccessSheet(bookingCode: bookingCode),
      );

      if (!mounted) return;
      context.go(
        destination == BookingSuccessAction.viewHistory
            ? AppRoutes.appointments
            : AppRoutes.home,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat janji temu: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Ringkasan Janji Temu'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  children: [
                    const _SectionLabel('LOKASI'),
                    _DarkBar(
                      icon: Icons.location_on,
                      text: 'Ciputra Hospital Surabaya',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionLabel(widget.booking.kind.label.toUpperCase()),
                    _BookingCard(
                      booking: widget.booking,
                      isExpanded: _isExpanded,
                      onToggle: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      onEdit: _edit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: '+ Tambah ${widget.booking.kind.label}',
                      expand: true,
                      background: AppColors.accentSoft,
                      onPressed: () => context.go(AppRoutes.doctors),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Anda dapat membuat lebih dari 1 '
                      '${widget.booking.kind.label}',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    _TermsCheckbox(
                      value: _agreedToTerms,
                      onChanged: (value) =>
                          setState(() => _agreedToTerms = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Konfirmasi',
                      expand: true,
                      isLoading: _isSubmitting,
                      background: AppColors.accentSoft,
                      onPressed: _submit,
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.bodySm.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DarkBar extends StatelessWidget {
  const _DarkBar({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.white),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The collapsible slate card summarising one booking.
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
  });

  final Booking booking;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('summaryToggle'),
            onTap: onToggle,
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 21,
                  color: AppColors.white,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    booking.patientName ?? '-',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: AppMotion.fast,
                  child: const Icon(
                    Icons.expand_more,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: AppColors.white, height: AppSpacing.xl),
            Row(
              children: [
                Icon(
                  booking.kind == BookingKind.videoCall
                      ? Icons.videocam
                      : Icons.medical_information,
                  size: 24,
                  color: AppColors.white,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${booking.kind.label} 1',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('summaryEdit'),
                  tooltip: 'Ubah',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Field(label: 'Dokter', value: booking.doctorName),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                booking.specialty ?? '',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Field(
                    label: 'Tanggal',
                    value: booking.date == null
                        ? null
                        : DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(booking.date!),
                  ),
                ),
                Expanded(
                  child: _Field(label: 'Waktu', value: booking.slot?.label),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Field(label: 'Jenis Jaminan', value: booking.paymentMethod),
            if (booking.company != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _Field(
                  label: 'Asuransi/Perusahaan',
                  value: booking.company,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? '-',
          style: AppTypography.bodySm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('summaryTerms'),
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
                children: const [
                  TextSpan(text: 'Dengan ini, saya setuju untuk mengikuti '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' yang berlaku'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
