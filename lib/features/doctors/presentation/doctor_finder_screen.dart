import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/textured_background.dart';
import '../../booking/domain/booking.dart';
import '../../booking/widgets/practice_calendar.dart';
import '../../booking/widgets/specialty_picker_sheet.dart';
import '../data/catalog_repository.dart';
import '../data/doctor_repository.dart';
import '../domain/clinic.dart';
import 'widgets/doctor_picker_sheet.dart';
import '../../../core/theme/app_elevation.dart';

/// Find a doctor by clinic, name, and date — the entry point to their
/// schedule.
class DoctorFinderScreen extends ConsumerStatefulWidget {
  const DoctorFinderScreen({super.key});

  @override
  ConsumerState<DoctorFinderScreen> createState() => _DoctorFinderScreenState();
}

class _DoctorFinderScreenState extends ConsumerState<DoctorFinderScreen> {
  String? _clinic;
  String? _doctorId;
  String? _doctorName;
  DateTime? _date;

  Future<void> _pickClinic() async {
    final clinics = ref.read(clinicsProvider).valueOrNull ?? [];
    final selectedClinic = clinics.where((c) => c.displayName == _clinic).firstOrNull;
    
    final picked = await showModalBottomSheet<Clinic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecialtyPickerSheet(
        selected: selectedClinic,
        title: 'Pilih Klinik',
        searchHint: 'Cari Klinik',
      ),
    );

    if (picked != null) setState(() => _clinic = picked.displayName);
  }

  Future<void> _pickDoctor() async {
    final doctors = ref.read(doctorsProvider);
    final matching = _clinic == null
        ? doctors
        : doctors.where((d) => d.specialty == _clinic).toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorPickerSheet(
        doctors: matching.isEmpty ? doctors : matching,
        selectedId: _doctorId,
      ),
    );

    if (picked == null) return;
    final doctor = doctors.firstWhere((d) => d.id == picked);
    setState(() {
      _doctorId = doctor.id;
      _doctorName = doctor.name;
      // The clinic follows from the doctor when it was not chosen first.
      _clinic ??= doctor.specialty;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DatePickerSheet(selected: _date),
    );

    if (picked != null) setState(() => _date = picked);
  }

  void _search() {
    if (_doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dokter terlebih dahulu.')),
      );
      return;
    }

    context.push(
      '${AppRoutes.doctorSchedule}/$_doctorId',
      extra: _date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 60),
                  Illustrations.doctorAtDesk(width: 300),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _Panel(
                  clinic: _clinic,
                  doctorName: _doctorName,
                  date: _date,
                  onClinicTap: _pickClinic,
                  onDoctorTap: _pickDoctor,
                  onDateTap: _pickDate,
                  onSearch: _search,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: AppBackButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The slate card holding the three criteria and the search button.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.clinic,
    required this.doctorName,
    required this.date,
    required this.onClinicTap,
    required this.onDoctorTap,
    required this.onDateTap,
    required this.onSearch,
  });

  final String? clinic;
  final String? doctorName;
  final DateTime? date;
  final VoidCallback onClinicTap;
  final VoidCallback onDoctorTap;
  final VoidCallback onDateTap;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Jadwal Dokter',
            style: AppTypography.headingLg.copyWith(
              fontSize: 24,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cari Jadwal dokter sesuai\ndengan kebutuhanmu',
            textAlign: TextAlign.center,
            style: AppTypography.inputText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _CriteriaRow(
            key: const Key('finderClinic'),
            label: clinic ?? 'Pilih Klinik',
            isFilled: clinic != null,
            onTap: onClinicTap,
          ),
          const SizedBox(height: AppSpacing.md),
          _CriteriaRow(
            key: const Key('finderDoctor'),
            label: doctorName ?? 'Cari Nama Dokter',
            isFilled: doctorName != null,
            onTap: onDoctorTap,
          ),
          const SizedBox(height: AppSpacing.md),
          _CriteriaRow(
            key: const Key('finderDate'),
            label: date == null
                ? 'Pilih Jadwal'
                : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date!),
            isFilled: date != null,
            onTap: onDateTap,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.light(label: 'Cari', onPressed: onSearch),
        ],
      ),
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  const _CriteriaRow({
    super.key,
    required this.label,
    required this.isFilled,
    required this.onTap,
  });

  final String label;
  final bool isFilled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppElevation.level2,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inputText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isFilled
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sheet wrapping the practice calendar, with clear and confirm actions.
class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({required this.selected});

  final DateTime? selected;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime? _date = widget.selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PracticeCalendar(
            kind: BookingKind.appointment,
            selected: _date,
            onSelected: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Hapus',
                  style: AppTypography.button.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.of(context).pop(_date),
                child: Text(
                  'Pilih',
                  style: AppTypography.button.copyWith(
                    color: AppColors.white,
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
