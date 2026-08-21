import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../widgets/practice_calendar.dart';
import '../../../core/theme/app_elevation.dart';
import '../../doctors/data/catalog_repository.dart';

/// Pick the day and time slot, for either booking kind.
class BookingScheduleScreen extends StatefulWidget {
  const BookingScheduleScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  late DateTime? _date = widget.booking.date;
  late BookingSlot? _slot = widget.booking.slot;

  void _confirm() {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu.')),
      );
      return;
    }
    if (_slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jam telekonsultasi.')),
      );
      return;
    }

    context.push(
      AppRoutes.bookingPatient,
      extra: widget.booking.copyWith(
        date: _date,
        slot: _slot,
        session: _slot?.session,
        slotNumber: _slot?.slotNumber,
        operationalTimeCode: _slot?.operationalTimeCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: widget.booking.kind.scheduleTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  children: [
                    Text(
                      'Metode Konsultasi',
                      textAlign: TextAlign.justify,
                      style: AppTypography.inputText.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentSoft,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MethodChip(kind: widget.booking.kind),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Pilih Tanggal',
                      style: AppTypography.inputText.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PracticeCalendar(
                      kind: widget.booking.kind,
                      selected: _date,
                      onSelected: (value) => setState(() {
                        _date = value;
                        // Slots belong to a day, so a new day clears the pick.
                        _slot = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SlotPanel(
                      booking: widget.booking,
                      date: _date,
                      selected: _slot,
                      onSelected: (value) => setState(() => _slot = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.booking.kind.leadTimeNote,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 15,
                        height: 1.25,
                        color: AppColors.accentSoft,
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
                child: AppButton(
                  label: 'Lanjut',
                  expand: true,
                  background: AppColors.accentSoft,
                  onPressed: _confirm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The read-only reminder of which consultation method this booking uses.
class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.kind});

  final BookingKind kind;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          boxShadow: AppElevation.level2,
        ),
        child: Container(
          height: 48,
          constraints: const BoxConstraints(minWidth: 144),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                kind == BookingKind.videoCall
                    ? Icons.videocam
                    : Icons.person_outline,
                size: 23,
                color: AppColors.accentSoft,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                kind.label,
                style: AppTypography.inputText.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark panel of bookable times for the chosen day.
class _SlotPanel extends ConsumerWidget {
  const _SlotPanel({
    required this.booking,
    required this.date,
    required this.selected,
    required this.onSelected,
  });

  final Booking booking;
  final DateTime? date;
  final BookingSlot? selected;
  final ValueChanged<BookingSlot> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (date == null) {
      return _buildContainer(
        child: Text(
          'Pilih tanggal untuk melihat jam yang tersedia.',
          style: AppTypography.bodySm.copyWith(
            fontSize: 14,
            color: const Color(0xCCDDDFF3),
          ),
        ),
      );
    }

    final query = SlotQuery(
      doctorId: booking.doctorId ?? '',
      unitCode: booking.unitCode ?? '',
      date: date!,
    );

    final slotsAsync = ref.watch(slotsProvider(query));
    final schedulesAsync = ref.watch(doctorSchedulesProvider(query.doctorId));

    return slotsAsync.when(
      loading: () => _buildContainer(
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      ),
      error: (e, _) => _buildContainer(
        child: Text(
          'Gagal memuat jadwal. ${e.toString()}',
          style: AppTypography.bodySm.copyWith(color: AppColors.white),
        ),
      ),
      data: (daySlots) {
        if (daySlots.isEmpty) {
          return _buildContainer(
            child: Text(
              'Tidak ada jam yang tersedia pada tanggal ini.',
              style: AppTypography.bodySm.copyWith(
                fontSize: 14,
                color: const Color(0xCCDDDFF3),
              ),
            ),
          );
        }

        // Look up operationalTimeCode from the doctor's weekly schedule for this day.
        String? getOperationalTimeCode(int session) {
          final schedules = schedulesAsync.valueOrNull;
          if (schedules == null) return null;
          
          final dayNumber = date!.weekday; // 1 = Monday, 7 = Sunday
          for (final schedule in schedules) {
            if (schedule.unitCode == query.unitCode && schedule.dayNumber == dayNumber) {
              // We check if this schedule's windows contain the session
              if (schedule.windows.any((w) => w.session == session)) {
                return schedule.operationalTimeCode;
              }
            }
          }
          return null;
        }

        return _buildContainer(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final bookable in daySlots.slots)
                _SlotChip(
                  slot: BookingSlot(
                    start: DateFormat('HH:mm').parse(bookable.start).copyWith(
                          year: date!.year,
                          month: date!.month,
                          day: date!.day,
                        ),
                    end: DateFormat('HH:mm').parse(bookable.end).copyWith(
                          year: date!.year,
                          month: date!.month,
                          day: date!.day,
                        ),
                    session: bookable.session,
                    slotNumber: bookable.number,
                    operationalTimeCode: getOperationalTimeCode(bookable.session),
                  ),
                  isSelected: selected?.start.hour ==
                          DateFormat('HH:mm').parse(bookable.start).hour &&
                      selected?.start.minute ==
                          DateFormat('HH:mm').parse(bookable.start).minute,
                  onTap: () {
                    final start = DateFormat('HH:mm').parse(bookable.start);
                    final end = DateFormat('HH:mm').parse(bookable.end);
                    onSelected(
                      BookingSlot(
                        start: DateTime(
                          date!.year,
                          date!.month,
                          date!.day,
                          start.hour,
                          start.minute,
                        ),
                        end: DateTime(
                          date!.year,
                          date!.month,
                          date!.day,
                          end.hour,
                          end.minute,
                        ),
                        session: bookable.session,
                        slotNumber: bookable.number,
                        operationalTimeCode: getOperationalTimeCode(bookable.session),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Jam',
            style: AppTypography.inputText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFDDDFF3),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final BookingSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Selected reads as an outlined white chip; taken slots dim out.
    final background = isSelected ? AppColors.white : const Color(0xFFDDDFF3);
    final opacity = slot.isAvailable ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            width: 139,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFDDDFF3)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              slot.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: 0.33,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
