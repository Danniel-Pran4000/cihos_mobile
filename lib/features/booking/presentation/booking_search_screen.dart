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
import '../../doctors/domain/clinic.dart';
import '../domain/booking.dart';
import '../widgets/practice_calendar.dart';
import '../widgets/specialty_picker_sheet.dart';

/// Search entry for a booking — by doctor name, specialty, or date. Serves
/// both appointments and video calls; [kind] decides the copy and lead time.
class BookingSearchScreen extends StatefulWidget {
  const BookingSearchScreen({super.key, required this.kind});

  final BookingKind kind;

  @override
  State<BookingSearchScreen> createState() => _BookingSearchScreenState();
}

class _BookingSearchScreenState extends State<BookingSearchScreen> {
  final _nameController = TextEditingController();

  Clinic? _specialty;
  DateTime? _date;

  /// The calendar only unfolds once the patient taps the date row.
  bool _isCalendarOpen = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickSpecialty() async {
    final picked = await showModalBottomSheet<Clinic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecialtyPickerSheet(selected: _specialty),
    );

    if (picked != null) setState(() => _specialty = picked);
  }

  void _search() {
    final booking = Booking(
      kind: widget.kind,
      doctorName: _nameController.text.trim(),
      specialty: _specialty?.displayName,
      unitCode: _specialty?.code,
      date: _date,
    );

    if (!booking.hasSearchCriteria) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi salah satu: nama dokter, spesialisasi, '
              'atau tanggal.'),
        ),
      );
      return;
    }

    context.push(AppRoutes.bookingResults, extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: widget.kind.searchTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  children: [
                    _Note(
                      'Pencarian dapat berdasarkan salah satu pilihan saja '
                      'antara Nama Dokter / Spesialisasi / Tanggal.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Note(widget.kind.leadTimeNote),
                    const SizedBox(height: AppSpacing.lg),
                    _DarkBar(
                      icon: Icons.mark_email_unread_outlined,
                      label: widget.kind.guideLabel,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Panduan ${widget.kind.label} akan segera hadir.',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SearchByNameBar(
                      controller: _nameController,
                      onSubmitted: (_) => _search(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.xl),
                    _CriteriaPanel(
                      kind: widget.kind,
                      specialty: _specialty?.displayName,
                      date: _date,
                      onSpecialtyTapped: _pickSpecialty,
                      onDateTapped: () => setState(
                        () => _isCalendarOpen = !_isCalendarOpen,
                      ),
                    ),
                    if (_isCalendarOpen) ...[
                      const SizedBox(height: AppSpacing.lg),
                      PracticeCalendar(
                        kind: widget.kind,
                        selected: _date,
                        onSelected: (value) => setState(() {
                          _date = value;
                          _isCalendarOpen = false;
                        }),
                      ),
                    ],
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
                  label: 'Selanjutnya, Pilih Dokter',
                  expand: true,
                  background: AppColors.accentSoft,
                  onPressed: _search,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: AppTypography.bodySm.copyWith(
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: AppColors.accentSoft,
      ),
    );
  }
}

/// A slim dark bar with a leading icon, used for the two shortcuts.
class _DarkBar extends StatelessWidget {
  const _DarkBar({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.white),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark bar that doubles as the doctor-name field.
class _SearchByNameBar extends StatelessWidget {
  const _SearchByNameBar({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.white),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodySm.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              cursorColor: AppColors.white,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Cari Dokter',
                hintStyle: AppTypography.bodySm.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.textPrimary)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Atau',
            style: AppTypography.inputText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.textPrimary)),
      ],
    );
  }
}

/// The dark panel holding the specialty dropdown and the date row.
class _CriteriaPanel extends StatelessWidget {
  const _CriteriaPanel({
    required this.kind,
    required this.specialty,
    required this.date,
    required this.onSpecialtyTapped,
    required this.onDateTapped,
  });

  final BookingKind kind;
  final String? specialty;
  final DateTime? date;
  final VoidCallback onSpecialtyTapped;
  final VoidCallback onDateTapped;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('specialtyRow'),
            onTap: onSpecialtyTapped,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelLabel('Pilih Spesialisasi'),
                Row(
                  children: [
                    Expanded(
                      child: _PanelValue(specialty ?? 'Pilih Spesialisasi'),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFFDDDFF3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xCCDDDFF3), height: AppSpacing.xl),
          InkWell(
            onTap: onDateTapped,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelLabel('Pilih Tanggal'),
                Row(
                  children: [
                    Expanded(
                      child: _PanelValue(
                        date == null
                            ? kind.datePlaceholder
                            : DateFormat(
                                'EEEE, d MMMM yyyy',
                                'id_ID',
                              ).format(date!),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodySm.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    );
  }
}

class _PanelValue extends StatelessWidget {
  const _PanelValue(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodySm.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xCCDDDFF3),
      ),
    );
  }
}
