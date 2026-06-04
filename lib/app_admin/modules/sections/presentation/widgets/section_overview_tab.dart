import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/spacing/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/responsive/app_breakpoints.dart';
import '../../models/section_management_models.dart';
import '../design/section_management_tokens.dart';
import '../charts/section_analytics_charts.dart';
import 'section_management_primitives.dart';

class SectionOverviewTab extends StatelessWidget {
  const SectionOverviewTab({
    super.key,
    required this.record,
    required this.visibleAlerts,
    required this.snapshots,
  });

  final SectionManagementRecord record;
  final List<SectionAlert> visibleAlerts;
  final List<SectionLoadSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final sortedSnapshots = [...snapshots]
      ..sort((a, b) => b.usage.compareTo(a.usage));

    final metrics = [
      SectionMetricTile(
        label: 'Students',
        value: record.studentsCount.toString(),
        icon: Icons.groups_rounded,
        color: AppColors.primary,
        footer: '${record.activeStudentsCount} active roster',
      ),
      SectionMetricTile(
        label: 'Capacity',
        value: '${record.capacityUsagePercent}%',
        icon: Icons.speed_rounded,
        color: capacityBandColor(record.capacityBand),
        footer: '${record.capacity} total seats',
      ),
      SectionMetricTile(
        label: 'Assigned subjects',
        value: record.subjectsCount.toString(),
        icon: Icons.menu_book_rounded,
        color: AppColors.secondary,
        footer: '${record.subjects.length} teaching blocks',
      ),
      SectionMetricTile(
        label: 'Assigned staff',
        value: record.staffCount.toString(),
        icon: Icons.badge_rounded,
        color: AppColors.info,
        footer:
            '${record.doctorsCount} doctors, ${record.assistantsCount} assistants',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(metrics: metrics),
        if (visibleAlerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final alert in visibleAlerts)
                SizedBox(
                  width: isDesktop ? 360 : double.infinity,
                  child: SectionAlertBanner(alert: alert),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ResponsiveTwoUp(
          leading: SectionDonutChartCard(
            title: 'Student distribution',
            subtitle:
                'Roster health by active, inactive, and at-risk student states.',
            points: record.studentDistribution,
            centerLabel: 'Students',
          ),
          trailing: SectionBarChartCard(
            title: 'Capacity usage',
            subtitle:
                'Live occupancy compared with available seats and waitlist pressure.',
            points: [
              SectionChartPoint(
                label: 'Filled',
                value: record.studentsCount.toDouble(),
              ),
              SectionChartPoint(
                label: 'Free',
                value: math.max(record.availableSeats, 0).toDouble(),
              ),
              SectionChartPoint(
                label: 'Waitlist',
                value: record.waitlistCount.toDouble(),
              ),
            ],
            color: capacityBandColor(record.capacityBand),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ResponsiveTwoUp(
          leading: SectionLineChartCard(
            title: 'Section performance',
            subtitle:
                'Rolling composite score from GPA health, attendance, and delivery rhythm.',
            points: record.performanceTrend,
            color: AppColors.primary,
          ),
          trailing: SectionLoadComparisonCard(
            title: 'Overloaded and empty sections',
            subtitle:
                'Compare nearby cohorts before approving transfers or capacity changes.',
            snapshots: sortedSnapshots.take(4).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ResponsiveTwoUp(
          leading: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionPanelHeader(
                  title: 'Subject delivery pulse',
                  subtitle:
                      'Completion and staffing coverage across the assigned subjects.',
                ),
                const SizedBox(height: AppSpacing.md),
                for (final subject in record.subjects) ...[
                  _SubjectPulseRow(subject: subject),
                  if (subject != record.subjects.last)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
          trailing: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionPanelHeader(
                  title: 'Staff coverage',
                  subtitle:
                      'Teaching load and readiness across doctors and assistants.',
                ),
                const SizedBox(height: AppSpacing.md),
                for (
                  var index = 0;
                  index < record.staff.take(5).length;
                  index++
                ) ...[
                  _StaffPulseRow(member: record.staff[index]),
                  if (index != math.min(record.staff.length, 5) - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<Widget> metrics;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: isDesktop ? 1.45 : 1.10,
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }
}

class _ResponsiveTwoUp extends StatelessWidget {
  const _ResponsiveTwoUp({required this.leading, required this.trailing});

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    if (!isDesktop) {
      return Column(
        children: [
          leading,
          const SizedBox(height: AppSpacing.lg),
          trailing,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leading),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: trailing),
      ],
    );
  }
}

class _SubjectPulseRow extends StatelessWidget {
  const _SubjectPulseRow({required this.subject});

  final SectionSubjectRecord subject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${subject.code} • ${subject.title}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            StatusBadge(subject.status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${subject.instructorName} • ${subject.lecturesCount} lectures',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SectionCapacityBar(
          value: subject.completionRate,
          label: '${(subject.completionRate * 100).round()}% complete',
        ),
      ],
    );
  }
}

class _StaffPulseRow extends StatelessWidget {
  const _StaffPulseRow({required this.member});

  final SectionStaffRecord member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SectionAvatar(
          label: member.initials,
          backgroundColor: member.role == 'Doctor'
              ? AppColors.primary
              : AppColors.info,
          radius: 20,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '${member.role} • ${member.focusArea}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 110,
          child: SectionCapacityBar(
            value: member.loadRate,
            label: '${(member.loadRate * 100).round()}%',
          ),
        ),
      ],
    );
  }
}
