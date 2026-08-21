import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_view.dart';
import '../../doctors/data/catalog_repository.dart';

import '../../doctors/domain/clinic.dart';

/// The searchable specialty list, opened from the booking search panel.
///
/// Pops the chosen clinic, or null when the sheet is dismissed.
class SpecialtyPickerSheet extends ConsumerStatefulWidget {
  const SpecialtyPickerSheet({
    super.key,
    this.selected,
    this.title = 'Pilih Spesialisasi',
    this.searchHint = 'Cari Spesialisasi',
  });

  final Clinic? selected;

  /// The clinic picker reuses this sheet with its own wording.
  final String title;
  final String searchHint;

  @override
  ConsumerState<SpecialtyPickerSheet> createState() =>
      _SpecialtyPickerSheetState();
}

class _SpecialtyPickerSheetState extends ConsumerState<SpecialtyPickerSheet> {
  final _searchController = TextEditingController();

  late Clinic? _selected = widget.selected;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(clinicsProvider);
    final matches = clinicsAsync.maybeWhen(
      data: (clinics) => clinics
          .where(
            (c) => c.displayName.toLowerCase().contains(_query.toLowerCase()),
          )
          .toList(),
      orElse: () => const <Clinic>[],
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.headingMd.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: AppTypography.bodySm.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncView(
                value: clinicsAsync,
                onRetry: () => ref.invalidate(clinicsProvider),
                isEmpty: (_) => matches.isEmpty,
                emptyTitle: 'Spesialisasi tidak ditemukan',
                builder: (_) => ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final clinic = matches[index];
                    return InkWell(
                      onTap: () => setState(() => _selected = clinic),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                clinic.displayName,
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 15,
                                  fontWeight: clinic.code == _selected?.code
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (clinic.code == _selected?.code)
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: AppColors.accentSoft,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppButton(
                label: 'Tampilkan Hasil Pencarian',
                expand: true,
                background: AppColors.accentSoft,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
