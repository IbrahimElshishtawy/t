import 'package:flutter/material.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/spacing/app_spacing.dart';
import '../../../shared/models/schedule_models.dart';
import '../models/section_management_models.dart';
import 'design/section_management_tokens.dart';
import 'widgets/section_overview_tab.dart';
import 'widgets/section_schedule_tab.dart';
import 'widgets/section_staff_tab.dart';
import 'widgets/section_students_tab.dart';
import 'widgets/section_subjects_tab.dart';
import 'widgets/section_desktop_sidebar.dart';
import 'widgets/sections_mock_data.dart';
import 'widgets/section_hero_header.dart';
import 'widgets/section_portfolio_strip.dart';
import 'widgets/section_tab_bar.dart';

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
            child: SectionBackdropOrb(
              size: 280,
              color: SectionManagementPalette.orbPrimary(context),
            ),
          ),
          Positioned(
            top: 280,
            left: -100,
            child: SectionBackdropOrb(
              size: 240,
              color: SectionManagementPalette.orbSuccess(context),
            ),
          ),
          Positioned(
            bottom: -120,
            right: 160,
            child: SectionBackdropOrb(
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
                          SectionHeroHeader(
                            record: _selectedRecord,
                            compact: constraints.maxWidth < 900,
                            onEdit: () => _showSnack(
                              'Edit panel is ready for form wiring to the real section editor.',
                            ),
                            onDelete: () => _showSnack(
                              'Delete action is intentionally mocked to protect the sample data.',
                            ),
                            onToggleActivation: _toggleSectionActivation,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionPortfolioStrip(
                            records: _records,
                            selectedRecord: _selectedRecord,
                            onSelectRecord: _selectRecord,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionTabBar(
                            activeTab: _activeTab,
                            onTabChanged: (tab) =>
                                setState(() => _activeTab = tab),
                          ),
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

}
