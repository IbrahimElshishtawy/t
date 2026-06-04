import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/spacing/app_spacing.dart';
import '../../models/student_management_models.dart';
import '../../widgets/student_module_charts.dart';
import '../../widgets/student_module_primitives.dart';
import 'student_profile_panel.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({
    super.key,
    required this.snapshot,
    required this.selectedStudent,
    required this.notificationStatus,
    required this.onExportCsv,
    required this.onOpenStudent,
    required this.onEditStudent,
    required this.onUploadDocuments,
    required this.onExportTranscript,
    required this.onDownloadBundle,
    required this.onApproveDocument,
    required this.onRejectDocument,
  });

  final StudentModuleSnapshot snapshot;
  final StudentProfile? selectedStudent;
  final String notificationStatus;
  final VoidCallback onExportCsv;
  final ValueChanged<StudentProfile> onOpenStudent;
  final VoidCallback onEditStudent;
  final VoidCallback onUploadDocuments;
  final VoidCallback onExportTranscript;
  final VoidCallback onDownloadBundle;
  final ValueChanged<StudentDocumentRecord> onApproveDocument;
  final ValueChanged<StudentDocumentRecord> onRejectDocument;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final chartWidth = width > 1400
        ? (width - 220) / 3
        : width > 980
            ? (width - 160) / 2
            : width - 48;
    final watchlist = snapshot.students.where((item) => item.isAtRisk).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: chartWidth,
              child: StudentKpiCard(
                label: 'Students',
                value: snapshot.totalStudents.toString(),
                caption: 'All enrolled student records in the module.',
                icon: Icons.groups_rounded,
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: StudentKpiCard(
                label: 'Courses',
                value: snapshot.activeCoursesCount.toString(),
                caption: 'Distinct active offerings assigned to students.',
                icon: Icons.auto_stories_rounded,
                color: AppColors.info,
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: StudentKpiCard(
                label: 'Pending',
                value: snapshot.pendingApprovals.toString(),
                caption: 'Registrations still waiting for admin approval.',
                icon: Icons.fact_check_rounded,
                color: AppColors.warning,
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: StudentKpiCard(
                label: 'Average GPA',
                value: snapshot.averageGpa.toStringAsFixed(2),
                caption: 'Live academic average across all student profiles.',
                icon: Icons.insights_rounded,
                color: AppColors.success,
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: StudentKpiCard(
                label: 'Attendance',
                value: '${snapshot.averageAttendance.toStringAsFixed(0)}%',
                caption:
                    'Average attendance health tracked from course records.',
                icon: Icons.co_present_rounded,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: StudentKpiCard(
                label: notificationStatus,
                value: snapshot.pendingDocuments.toString(),
                caption: 'Pending document reviews in the approval queue.',
                icon: Icons.file_open_rounded,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: chartWidth,
              child: StudentSectionCard(
                title: 'Enrollment trend',
                subtitle: 'Realtime line chart for enrollment momentum.',
                trailing: IconButton(
                  onPressed: onExportCsv,
                  icon: const Icon(Icons.download_rounded),
                ),
                child: SizedBox(
                  height: 260,
                  child: StudentLineTrendChart(
                    points: snapshot.enrollmentTrend,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: StudentSectionCard(
                title: 'Department distribution',
                subtitle: 'Student distribution by department.',
                child: SizedBox(
                  height: 260,
                  child: StudentDepartmentBarChart(
                    distribution: snapshot.departmentDistribution,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: StudentSectionCard(
                title: 'Approval queue',
                subtitle:
                    'Donut split across pending, active, and watchlist students.',
                child: SizedBox(
                  height: 260,
                  child: StudentDonutChart(
                    pending: snapshot.pendingApprovals,
                    active: snapshot.students
                        .where(
                          (item) =>
                              item.enrollmentStatus ==
                              StudentEnrollmentStatus.active,
                        )
                        .length,
                    watchlist: watchlist,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final showSide =
                constraints.maxWidth > 1200 && selectedStudent != null;
            if (!showSide) {
              return Column(
                children: [
                  _PendingQueuesCard(
                    snapshot: snapshot,
                    onOpenStudent: onOpenStudent,
                  ),
                  if (selectedStudent != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    StudentProfilePanel(
                      student: selectedStudent!,
                      onEditStudent: onEditStudent,
                      onUploadDocuments: onUploadDocuments,
                      onExportTranscript: onExportTranscript,
                      onDownloadBundle: onDownloadBundle,
                      onApproveDocument: onApproveDocument,
                      onRejectDocument: onRejectDocument,
                    ),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _PendingQueuesCard(
                    snapshot: snapshot,
                    onOpenStudent: onOpenStudent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 4,
                  child: StudentProfilePanel(
                    student: selectedStudent!,
                    onEditStudent: onEditStudent,
                    onUploadDocuments: onUploadDocuments,
                    onExportTranscript: onExportTranscript,
                    onDownloadBundle: onDownloadBundle,
                    onApproveDocument: onApproveDocument,
                    onRejectDocument: onRejectDocument,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final alert in snapshot.alerts.take(3))
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 960
                    ? double.infinity
                    : 240,
                child: _AlertTile(alert: alert),
              ),
          ],
        ),
      ],
    );
  }
}

class _PendingQueuesCard extends StatelessWidget {
  const _PendingQueuesCard({
    required this.snapshot,
    required this.onOpenStudent,
  });

  final StudentModuleSnapshot snapshot;
  final ValueChanged<StudentProfile> onOpenStudent;

  @override
  Widget build(BuildContext context) {
    final pending = snapshot.students
        .where(
          (item) =>
              item.enrollmentStatus ==
                  StudentEnrollmentStatus.pendingApproval ||
              item.pendingDocumentCount > 0,
        )
        .toList(growable: false);
    return StudentSectionCard(
      title: 'Approvals and document queue',
      subtitle:
          'Scrollable approval table highlighting pending enrollment packages, missing document reviews, and at-risk signals.',
      child: SizedBox(
        height: 360,
        child: DataTable2(
          fixedTopRows: 1,
          minWidth: 860,
          columns: const [
            DataColumn2(label: Text('Student'), size: ColumnSize.L),
            DataColumn2(label: Text('Department')),
            DataColumn2(label: Text('Status')),
            DataColumn2(label: Text('Pending docs')),
            DataColumn2(label: Text('GPA')),
            DataColumn2(label: Text('Action')),
          ],
          rows: [
            for (final student in pending)
              DataRow2(
                onTap: () => onOpenStudent(student),
                cells: [
                  DataCell(Text(student.fullName)),
                  DataCell(Text(student.department)),
                  DataCell(
                    StudentStatusPill(
                      label: student.enrollmentStatus.label,
                      color: student.enrollmentStatus ==
                              StudentEnrollmentStatus.pendingApproval
                          ? AppColors.warning
                          : AppColors.info,
                    ),
                  ),
                  DataCell(Text(student.pendingDocumentCount.toString())),
                  DataCell(Text(student.gpa.toStringAsFixed(2))),
                  const DataCell(Icon(Icons.chevron_right_rounded)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final StudentModuleAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      StudentAlertSeverity.info => AppColors.info,
      StudentAlertSeverity.success => AppColors.success,
      StudentAlertSeverity.warning => AppColors.warning,
      StudentAlertSeverity.critical => AppColors.danger,
    };
    return StudentGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentStatusPill(label: alert.badgeLabel, color: color),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(alert.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(alert.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(alert.body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
