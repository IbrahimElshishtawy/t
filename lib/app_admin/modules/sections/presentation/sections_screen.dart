import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/colors/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/spacing/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/models/schedule_models.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/section_management_models.dart';
import 'design/section_management_tokens.dart';
import 'widgets/section_management_primitives.dart';
import 'widgets/section_overview_tab.dart';
import 'widgets/section_schedule_tab.dart';
import 'widgets/section_staff_tab.dart';
import 'widgets/section_students_tab.dart';
import 'widgets/section_subjects_tab.dart';
import 'widgets/section_desktop_sidebar.dart';
import 'widgets/sections_mock_data.dart';

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  late final List<SectionManagementRecord> _records;
  late SectionManagementRecord _selectedRecord;
  late DateTime _selectedDay;

  SectionDetailTab _activeTab = SectionDetailTab.overview;
  SectionScheduleViewMode _scheduleViewMode = SectionScheduleViewMode.week;

  @override
  void initState() {
    super.initState();
    _records = buildMockSections();
    _selectedRecord = _records.first;
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = AppBreakpoints.resolve(context);
    final isDesktop = deviceType == DeviceScreenType.desktop;
    final isTablet = deviceType == DeviceScreenType.tablet;
    final horizontalPadding = isDesktop
        ? AppSpacing.xxxl
        : isTablet
            ? AppSpacing.xl
            : AppSpacing.md;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: SectionManagementPalette.pageGradient(context),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _BackdropOrb(
              size: 280,
              color: SectionManagementPalette.orbPrimary(context),
            ),
          ),
          Positioned(
            top: 280,
            left: -100,
            child: _BackdropOrb(
              size: 240,
              color: SectionManagementPalette.orbSuccess(context),
            ),
          ),
          Positioned(
            bottom: -120,
            right: 160,
            child: _BackdropOrb(
              size: 260,
              color: SectionManagementPalette.orbWarning(context),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                AppSpacing.xxxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.shellMaxContentWidth,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showSidebarPreview = constraints.maxWidth >= 1560;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroHeader(context, constraints.maxWidth < 900),
                          const SizedBox(height: AppSpacing.lg),
                          _buildPortfolioStrip(context),
                          const SizedBox(height: AppSpacing.lg),
                          _buildTabBar(),
                          const SizedBox(height: AppSpacing.lg),
                          if (showSidebarPreview)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildMainWorkspace(context)),
                                const SizedBox(width: AppSpacing.xl),
                                SizedBox(
                                  width: 288,
                                  child: _buildDesktopSidebar(context),
                                ),
                              ],
                            )
                          else
                            _buildMainWorkspace(context),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool compact) {
    final record = _selectedRecord;
    final capacityColor = capacityBandColor(record.capacityBand);
    final alertLabel = switch (record.capacityBand) {
      SectionCapacityBand.available =>
        '${record.availableSeats} seats available',
      SectionCapacityBand.almostFull => 'Almost full, review incoming adds',
      SectionCapacityBand.full => 'Section full, waitlist active',
    };

    return SectionGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroIdentity(context),
                const SizedBox(height: AppSpacing.lg),
                _buildHeroCapacityCard(context, alertLabel, capacityColor),
                const SizedBox(height: AppSpacing.lg),
                _buildHeroActions(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroIdentity(context),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoPill(
                            icon: Icons.apartment_rounded,
                            label: record.department,
                          ),
                          _InfoPill(
                            icon: Icons.school_rounded,
                            label: record.yearLabel,
                          ),
                          _InfoPill(
                            icon: Icons.auto_stories_rounded,
                            label: record.semesterLabel,
                          ),
                          _InfoPill(
                            icon: Icons.place_outlined,
                            label: record.locationLabel,
                          ),
                          _InfoPill(
                            icon: Icons.sync_rounded,
                            label: record.lastUpdatedLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildHeroActions(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildHeroCapacityCard(
                        context,
                        alertLabel,
                        capacityColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroIdentity(BuildContext context) {
    final record = _selectedRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Section Management',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(record.name, style: Theme.of(context).textTheme.displayMedium),
            _CodeBadge(code: record.code),
            StatusBadge(record.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          record.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: SectionManagementPalette.subtleText(context),
              ),
        ),
      ],
    );
  }

  Widget _buildHeroCapacityCard(
    BuildContext context,
    String alertLabel,
    Color accentColor,
  ) {
    final record = _selectedRecord;
    return AppCard(
      backgroundColor: SectionManagementPalette.frostedSurface(context),
      borderColor: accentColor.withValues(alpha: 0.20),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.people_alt_rounded, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacity management',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alertLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: accentColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCapacityBar(
            value: record.capacityUsage,
            label:
                '${record.studentsCount} filled of ${record.capacity} total seats',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniCapacityStat(
                  label: 'Available',
                  value: math.max(record.availableSeats, 0).toString(),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniCapacityStat(
                  label: 'Waitlist',
                  value: record.waitlistCount.toString(),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniCapacityStat(
                  label: 'Capacity %',
                  value: '${record.capacityUsagePercent}%',
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActions() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.end,
      children: [
        PremiumButton(
          label: 'Edit',
          icon: Icons.edit_outlined,
          isSecondary: true,
          onPressed: () => _showSnack(
            'Edit panel is ready for form wiring to the real section editor.',
          ),
        ),
        PremiumButton(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onPressed: () => _showSnack(
            'Delete action is intentionally mocked to protect the sample data.',
          ),
        ),
        PremiumButton(
          label: _selectedRecord.isActive ? 'Deactivate' : 'Activate',
          icon: _selectedRecord.isActive
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_outline_rounded,
          onPressed: _toggleSectionActivation,
        ),
      ],
    );
  }

  Widget _buildPortfolioStrip(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanelHeader(
          title: 'Section portfolio',
          subtitle:
              'Compare sibling cohorts, overloaded groups, and empty capacity before moving students.',
          trailing: Text(
            '${_records.length} active cohorts',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _records.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final record = _records[index];
              return SizedBox(
                width: 290,
                child: SectionPortfolioCard(
                  record: record,
                  selected: record.id == _selectedRecord.id,
                  onTap: () => _selectRecord(record),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: SectionManagementPalette.frostedSurface(
        context,
        lightAlpha: 0.72,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final tab in SectionDetailTab.values)
            SectionSegmentChip(
              label: _tabLabel(tab),
              selected: _activeTab == tab,
              onTap: () => setState(() => _activeTab = tab),
            ),
        ],
      ),
    );
  }

  Widget _buildMainWorkspace(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.entrance,
      switchOutCurve: AppMotion.emphasized,
      child: Container(
        key: ValueKey<String>(_activeTab.name),
        child: switch (_activeTab) {
          SectionDetailTab.overview => SectionOverviewTab(
              record: _selectedRecord,
              visibleAlerts: _buildVisibleAlerts(_selectedRecord),
              snapshots: _sectionSnapshots(),
            ),
          SectionDetailTab.students => SectionStudentsTab(
              selectedRecord: _selectedRecord,
              siblingRecords:
                  _records.where((r) => r.id != _selectedRecord.id).toList(),
              onMoveStudents: _moveStudents,
              onRemoveStudents: (studentIds) {
                final updated = _selectedRecord.copyWith(
                  students: _selectedRecord.students
                      .where((student) => !studentIds.contains(student.id))
                      .toList(),
                );
                final removedCount = studentIds.length;
                _replaceRecord(updated);
                _showSnack(
                    '$removedCount students were removed from ${updated.code}.');
              },
              onAddStudent: () => _showSnack(
                'Add student action is prepared for roster import or live search integration.',
              ),
              showSnack: _showSnack,
            ),
          SectionDetailTab.schedule => SectionScheduleTab(
              selectedDay: _selectedDay,
              viewMode: _scheduleViewMode,
              visibleDays: _visibleScheduleDays(),
              dayEvents: _eventsForDay(_selectedDay),
              eventsByDay: {
                for (final day in _visibleScheduleDays())
                  day: _eventsForDay(day),
              },
              onDaySelected: (day) => setState(() => _selectedDay = day),
              onViewModeChanged: (mode) =>
                  setState(() => _scheduleViewMode = mode),
            ),
          SectionDetailTab.subjects => SectionSubjectsTab(
              subjects: _selectedRecord.subjects,
              onAssignSubject: () => _showSnack(
                'Assign subject flow is ready for API-backed search and attach behavior.',
              ),
            ),
          SectionDetailTab.staff => SectionStaffTab(
              staff: _selectedRecord.staff,
              onAssignStaff: () => _showSnack(
                'Assign staff flow is staged for directory search integration.',
              ),
              onAssignMember: (member) => _showSnack(
                '${member.name} assignment control is in preview mode.',
              ),
              onUnassignMember: (member) => _showSnack(
                '${member.name} unassign confirmation is ready for backend wiring.',
              ),
            ),
        },
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final visibleAlerts = _buildVisibleAlerts(_selectedRecord);
    final previewEvents = _eventsForDay(_selectedDay).take(3).toList();

    return SectionDesktopSidebar(
      selectedRecord: _selectedRecord,
      records: _records,
      activeTab: _activeTab,
      visibleAlerts: visibleAlerts,
      previewEvents: previewEvents,
    );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final normalized = _dateOnly(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _visibleScheduleDays() {
    if (_scheduleViewMode == SectionScheduleViewMode.day) {
      return [_dateOnly(_selectedDay)];
    }

    final start = _startOfWeek(_selectedDay);
    return List<DateTime>.generate(
      5,
      (index) => start.add(Duration(days: index)),
    );
  }

  List<ScheduleEventModel> _eventsForDay(DateTime day) {
    return _selectedRecord.scheduleEvents
        .where((event) => _isSameDay(event.start, day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<SectionAlert> _buildVisibleAlerts(SectionManagementRecord record) {
    return [
      ...record.alerts,
      if (record.capacityBand == SectionCapacityBand.full)
        const SectionAlert(
          title: 'Capacity full',
          message:
              'The section is fully occupied. New student additions should route to waitlist or transfer flow.',
          severity: 'critical',
        ),
      if (record.capacityBand == SectionCapacityBand.almostFull)
        const SectionAlert(
          title: 'Capacity threshold',
          message:
              'This section is approaching its ceiling. Review transfers before approving new enrollments.',
          severity: 'warning',
        ),
    ];
  }

  List<SectionLoadSnapshot> _sectionSnapshots() {
    return _records
        .map(
          (record) => SectionLoadSnapshot(
            id: record.id,
            label: record.code,
            department: record.department,
            yearLabel: record.yearLabel,
            usedSeats: record.studentsCount,
            capacity: record.capacity,
          ),
        )
        .toList();
  }

  void _selectRecord(SectionManagementRecord record) {
    setState(() {
      _selectedRecord = record;
      _activeTab = SectionDetailTab.overview;
      _selectedDay = record.scheduleEvents.isNotEmpty
          ? record.scheduleEvents.first.start
          : DateTime.now();
    });
  }

  void _toggleSectionActivation() {
    final updated = _selectedRecord.copyWith(
      status: _selectedRecord.isActive ? 'Inactive' : 'Active',
    );
    _replaceRecord(updated);
    _showSnack('${updated.code} is now ${updated.status.toLowerCase()}.');
  }

  void _moveStudents(Set<String> studentIds, String targetId) {
    if (studentIds.isEmpty) return;

    final source = _selectedRecord;
    final targetIndex = _records.indexWhere((record) => record.id == targetId);
    final sourceIndex = _records.indexWhere((record) => record.id == source.id);
    if (targetIndex == -1 || sourceIndex == -1) return;

    final movingStudents = source.students
        .where((student) => studentIds.contains(student.id))
        .toList();
    if (movingStudents.isEmpty) return;

    final updatedSource = source.copyWith(
      students: source.students
          .where((student) => !studentIds.contains(student.id))
          .toList(),
    );

    final target = _records[targetIndex];
    final updatedTarget = target.copyWith(
      students: [
        ...target.students,
        ...movingStudents.map(
          (student) => student.copyWith(currentSectionCode: target.code),
        ),
      ],
    );

    setState(() {
      _records[sourceIndex] = updatedSource;
      _records[targetIndex] = updatedTarget;
      _selectedRecord = updatedSource;
    });

    _showSnack(
      '${movingStudents.length} students moved from ${source.code} to ${target.code}.',
    );
  }

  void _replaceRecord(SectionManagementRecord updated) {
    final index = _records.indexWhere((record) => record.id == updated.id);
    if (index == -1) return;
    setState(() {
      _records[index] = updated;
      _selectedRecord = updated;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _tabLabel(SectionDetailTab tab) => switch (tab) {
        SectionDetailTab.overview => 'Overview',
        SectionDetailTab.students => 'Students',
        SectionDetailTab.schedule => 'Schedule',
        SectionDetailTab.subjects => 'Subjects',
        SectionDetailTab.staff => 'Staff',
      };
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        code,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: SectionManagementPalette.frostedSurface(
          context,
          lightAlpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: SectionManagementPalette.subtleText(context),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MiniCapacityStat extends StatelessWidget {
  const _MiniCapacityStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
