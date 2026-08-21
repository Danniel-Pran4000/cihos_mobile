import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../domain/booking.dart';
import '../widgets/patient_picker_sheet.dart';

/// Choose which patient the booking is for, and how it will be paid.
class BookingPatientScreen extends StatefulWidget {
  const BookingPatientScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingPatientScreen> createState() => _BookingPatientScreenState();
}

class _BookingPatientScreenState extends State<BookingPatientScreen> {
  BookingPatient? _patient = BookingOptions.patients.last;
  String _paymentMethod = BookingOptions.paymentMethods.first;
  String? _company;

  Future<void> _pickPatient() async {
    final picked = await showModalBottomSheet<BookingPatient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PatientPickerSheet(selected: _patient),
    );

    if (picked != null) setState(() => _patient = picked);
  }

  void _confirm() {
    if (_patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pasien terlebih dahulu.')),
      );
      return;
    }

    if (_paymentMethod == 'Asuransi/Perusahaan' && _company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih asuransi atau perusahaan.')),
      );
      return;
    }

    context.push(
      AppRoutes.bookingSummary,
      extra: widget.booking.copyWith(
        patientName: _patient!.name,
        patientMedicalRecordNumber: _patient!.medicalRecordNumber,
        paymentMethod: _paymentMethod,
        company: _company,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInsurance = _paymentMethod == 'Asuransi/Perusahaan';

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Pilih Pasien'),
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
                      'Pilih pasien yang akan didaftarkan untuk '
                      '${widget.booking.kind.label}.',
                      textAlign: TextAlign.justify,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _GuideBar(kind: widget.booking.kind),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Pasien',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PatientField(patient: _patient, onTap: _pickPatient),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Jenis Jaminan',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final method in BookingOptions.paymentMethods)
                      _RadioRow(
                        label: method,
                        isSelected: _paymentMethod == method,
                        onTap: () => setState(() {
                          _paymentMethod = method;
                          if (method != 'Asuransi/Perusahaan') _company = null;
                        }),
                      ),
                    if (isInsurance) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Pilih Asuransi/Perusahaan',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CompanyField(
                        value: _company,
                        onChanged: (value) => setState(() => _company = value),
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
                  label: 'Konfirmasi',
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

/// The dark bar linking to the booking guide.
class _GuideBar extends StatelessWidget {
  const _GuideBar({required this.kind});

  final BookingKind kind;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Panduan ${kind.label} akan segera hadir.')),
        ),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 18,
                color: AppColors.white,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                    children: [
                      const TextSpan(text: 'Perlu bantuan? '),
                      TextSpan(
                        text: 'Lihat Panduan ${kind.label}.',
                        style: const TextStyle(
                          color: Color(0xFFDDDFF3),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFDDDFF3),
                        ),
                      ),
                    ],
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

/// The dark row showing the currently chosen patient and their record number.
class _PatientField extends StatelessWidget {
  const _PatientField({required this.patient, required this.onTap});

  final BookingPatient? patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        key: const Key('patientField'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: AppColors.white),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient?.name ?? 'Pilih Pasien',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDDDFF3),
                      ),
                    ),
                    Text(
                      patient?.medicalRecordNumber ?? '-',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDDDFF3),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFDDDFF3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.bodySm.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// The underlined insurer row, shown only for company-funded visits.
class _CompanyField extends StatelessWidget {
  const _CompanyField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        hint: Text(
          'Cari Asuransi/Perusahaan',
          style: AppTypography.bodySm.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
        style: AppTypography.bodySm.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        items: [
          for (final company in BookingOptions.companies)
            DropdownMenuItem(value: company, child: Text(company)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
