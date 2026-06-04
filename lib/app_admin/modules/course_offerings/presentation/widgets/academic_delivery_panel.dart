import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/spacing/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../models/course_offering_model.dart';
import 'offering_summary_card.dart';

class AcademicDeliveryPanel extends StatelessWidget {
  const AcademicDeliveryPanel({super.key, required this.offerings});

  final List<CourseOfferingModel> offerings;

  @override
  Widget build(BuildContext context) {
    final active = offerings
        .where((item) => item.status == CourseOfferingStatus.active)
        .length;
    final highDemand = offerings.where((item) => item.fillRate >= 0.85).length;
    final departments = offerings.map((item) => item.departmentName).toSet();
    final academicYears = offerings.map((item) => item.academicYear).toSet();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic delivery snapshot',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A cleaner split for active delivery, demand pressure, and academic coverage across the current offerings view.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OfferingInsightChip(
                label: '$active active now',
                color: AppColors.secondary,
              ),
              OfferingInsightChip(
                label: '$highDemand high-demand sections',
                color: AppColors.warning,
              ),
              OfferingInsightChip(
                label: '${departments.length} departments',
                color: AppColors.info,
              ),
              OfferingInsightChip(
                label: academicYears.isEmpty
                    ? 'No academic year data'
                    : academicYears.join(' • '),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
