import 'package:flutter/material.dart';

import '../../../../core/spacing/app_spacing.dart';
import '../../models/section_management_models.dart';
import 'section_management_primitives.dart';

class SectionPortfolioStrip extends StatelessWidget {
  const SectionPortfolioStrip({
    super.key,
    required this.records,
    required this.selectedRecord,
    required this.onSelectRecord,
  });

  final List<SectionManagementRecord> records;
  final SectionManagementRecord selectedRecord;
  final ValueChanged<SectionManagementRecord> onSelectRecord;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanelHeader(
          title: 'Section portfolio',
          subtitle:
              'Compare sibling cohorts, overloaded groups, and empty capacity before moving students.',
          trailing: Text(
            '${records.length} active cohorts',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: records.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final record = records[index];
              return SizedBox(
                width: 290,
                child: SectionPortfolioCard(
                  record: record,
                  selected: record.id == selectedRecord.id,
                  onTap: () => onSelectRecord(record),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
