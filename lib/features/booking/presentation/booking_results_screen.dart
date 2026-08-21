import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../doctors/domain/doctor.dart';
import '../domain/booking.dart';
import '../widgets/search_filter_sheet.dart';
import '../../../core/theme/app_elevation.dart';

/// Doctors matching the search, each with its own slot strip so a booking can
/// be started without opening the profile first.
class BookingResultsScreen extends ConsumerStatefulWidget {
  const BookingResultsScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<BookingResultsScreen> createState() =>
      _BookingResultsScreenState();
}

class _BookingResultsScreenState extends ConsumerState<BookingResultsScreen> {
  late Booking booking = widget.booking;

  Future<void> _openFilter() async {
    final filter = await showModalBottomSheet<SearchFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterSheet(
        kind: booking.kind,
        specialty: booking.specialty,
        date: booking.date,
      ),
    );

    if (filter == null) return;
    setState(() {
      // A cleared filter must actually clear, so rebuild rather than copyWith.
      booking = Booking(
        kind: booking.kind,
        doctorName: booking.doctorName,
        specialty: filter.specialty,
        date: filter.date,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matchingDoctors(ref.watch(doctorsProvider));

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Hasil Pencarian'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pilih Dokter',
                        style: AppTypography.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _FilterChip(
                      label: booking.kind.label,
                      onTap: _openFilter,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: matches.isEmpty
                    ? const _NoMatches()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          0,
                          AppSpacing.xxl,
                          AppSpacing.xxxl,
                        ),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) => _DoctorResultCard(
                          doctor: matches[index],
                          booking: booking,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Filters on whichever criteria the patient supplied.
  List<Doctor> _matchingDoctors(List<Doctor> all) {
    final method = booking.kind == BookingKind.videoCall
        ? ConsultationMethod.videoCall
        : ConsultationMethod.appointment;

    return all.where((doctor) {
      if (!doctor.supports(method)) return false;

      final name = booking.doctorName?.trim().toLowerCase() ?? '';
      if (name.isNotEmpty &&
          !doctor.name.toLowerCase().contains(name)) {
        return false;
      }

      final specialty = booking.specialty;
      if (specialty != null && doctor.specialty != specialty) return false;

      return true;
    }).toList();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        key: const Key('searchFilter'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune, size: 14, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One doctor plus the next few slots they have open.
class _DoctorResultCard extends StatelessWidget {
  const _DoctorResultCard({required this.doctor, required this.booking});

  final Doctor doctor;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    // Falls back to today when the search carried no date.
    final day = booking.date ?? DateTime.now();
    final slots = BookingOptions.slotsFor(day).take(4).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DoctorRow(doctor: doctor),
            const SizedBox(height: AppSpacing.md),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(day),
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final slot in slots)
                  _SlotPill(
                    slot: slot,
                    onTap: slot.isAvailable
                        ? () => context.push(
                            AppRoutes.bookingSchedule,
                            extra: booking.copyWith(
                              doctorId: doctor.id,
                              doctorName: doctor.name,
                              paramedicCode: doctor.code,
                              specialty: doctor.specialty,
                              unitCode: doctor.unitCode,
                              date: day,
                              slot: slot,
                            ),
                          )
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => context.push(
                  AppRoutes.bookingSchedule,
                  extra: booking.copyWith(
                    doctorId: doctor.id,
                    doctorName: doctor.name,
                    paramedicCode: doctor.code,
                    specialty: doctor.specialty,
                    unitCode: doctor.unitCode,
                  ),
                ),
                child: Text(
                  'Booking Jadwal',
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentSoft,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorRow extends StatelessWidget {
  const _DoctorRow({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: 56,
            height: 56,
            child: doctor.photoAsset == null
                ? const _PhotoPlaceholder()
                : Image.asset(
                    doctor.photoAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _PhotoPlaceholder(),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: AppTypography.titleMd.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 3),
              _MetaLine(icon: Icons.medical_services, text: doctor.specialty),
              _MetaLine(icon: Icons.location_on, text: doctor.hospital),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({required this.slot, required this.onTap});

  final BookingSlot slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: slot.isAvailable ? 1 : 0.4,
      child: Material(
        color: const Color(0xFFDDDFF3),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Text(
              slot.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.border,
      child: Icon(Icons.person, size: 28, color: AppColors.textTertiary),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Dokter tidak ditemukan', style: AppTypography.bodyMd),
        ],
      ),
    );
  }
}
