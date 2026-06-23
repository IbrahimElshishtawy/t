import 'dart:math' as math;

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/demo_data_service.dart';
import '../../subjects/models/subject_management_models.dart';
import '../models/schedule_models.dart';
import '../services/schedule_api_service.dart';

class ScheduleRepository {
  ScheduleRepository(this._api, this._demoDataService);

  final ScheduleApiService _api;
  final DemoDataService _demoDataService;

  List<ScheduleEventItem>? _cache;
  ScheduleLookupBundle? _lookups;

  Future<ScheduleBundle> fetchSchedule({
    required ScheduleFilters filters,
  }) async {
    _ensureSeeded();

    if (!AppConfig.useMockData) {
      try {
        final remote = await _api.fetchEvents(filters: filters);
        _cache = remote;
        _rebuildLookups();
      } catch (_) {}
    }

    return ScheduleBundle(
      events: List<ScheduleEventItem>.unmodifiable(_cache!),
      lookups: _lookups!,
    );
  }

  Future<ScheduleMutationResult> createEvent(
    ScheduleEventUpsertPayload payload,
  ) async {
    _ensureSeeded();
    var department = payload.department;
    var yearLabel = payload.yearLabel;
    var section = payload.section;
    var subject = payload.subject;
    var instructor = payload.instructor;
    var sectionId = payload.sectionId;
    var subjectId = payload.subjectId;
    var instructorId = payload.instructorId;

    if (payload.courseOfferingId != null && payload.courseOfferingId!.isNotEmpty) {
      for (final event in _cache ?? const <ScheduleEventItem>[]) {
        if (event.courseOfferingId == payload.courseOfferingId) {
          department = event.department;
          yearLabel = event.yearLabel;
          if (section == 'Section' || section.isEmpty) {
            section = event.section;
            sectionId = event.sectionId;
          }
          if (subject == 'Subject' || subject.isEmpty) {
            subject = event.subject;
            subjectId = event.subjectId;
          }
          if (instructor == 'Instructor' || instructor.isEmpty) {
            instructor = event.instructor;
            instructorId = event.instructorId;
          }
          break;
        }
      }
    }

    final local = payload.toEvent(
      id: 'SCH-${DateTime.now().microsecondsSinceEpoch}',
      isSynced: false,
    ).copyWith(
      department: department,
      yearLabel: yearLabel,
      section: section,
      subject: subject,
      instructor: instructor,
      sectionId: sectionId,
      subjectId: subjectId,
      instructorId: instructorId,
    );

    if (!AppConfig.useMockData) {
      try {
        final remote = await _api.createEvent(payload);
        _cache = [remote.copyWith(isSynced: true), ..._cache!];
      } catch (_) {
        _cache = [local, ..._cache!];
      }
    } else {
      _cache = [local, ..._cache!];
    }

    _rebuildLookups();
    return ScheduleMutationResult(
      events: List<ScheduleEventItem>.unmodifiable(_cache!),
      lookups: _lookups!,
      message: 'Schedule event saved successfully.',
      highlightedEventId: _cache!.first.id,
    );
  }

  Future<ScheduleMutationResult> updateEvent({
    required String eventId,
    required ScheduleEventUpsertPayload payload,
  }) async {
    _ensureSeeded();
    final existing = _cache!.firstWhere(
      (event) => event.id == eventId,
      orElse: () =>
          throw AppException('The selected schedule event was not found.'),
    );

    final local = payload.toEvent(id: existing.id, isSynced: existing.isSynced);
    if (!AppConfig.useMockData) {
      try {
        final remote = await _api.updateEvent(eventId, payload);
        _replace(remote.copyWith(isSynced: true));
      } catch (_) {
        _replace(local);
      }
    } else {
      _replace(local);
    }

    _rebuildLookups();
    return ScheduleMutationResult(
      events: List<ScheduleEventItem>.unmodifiable(_cache!),
      lookups: _lookups!,
      message: 'Schedule event updated successfully.',
      highlightedEventId: eventId,
    );
  }

  Future<ScheduleMutationResult> deleteEvent({required String eventId}) async {
    _ensureSeeded();
    _cache = _cache!
        .where((event) => event.id != eventId)
        .toList(growable: false);
    if (!AppConfig.useMockData) {
      try {
        await _api.deleteEvent(eventId);
      } catch (_) {}
    }

    _rebuildLookups();
    return ScheduleMutationResult(
      events: List<ScheduleEventItem>.unmodifiable(_cache!),
      lookups: _lookups!,
      message: 'Schedule event deleted successfully.',
    );
  }

  Future<ScheduleMutationResult> rescheduleEvent({
    required ScheduleEventItem event,
    required DateTime targetStart,
    required DateTime targetEnd,
  }) {
    return updateEvent(
      eventId: event.id,
      payload: ScheduleEventUpsertPayload(
        title: event.title,
        section: event.section,
        subject: event.subject,
        instructor: event.instructor,
        location: event.location,
        status: event.status,
        type: event.type,
        startAt: targetStart,
        endAt: targetEnd,
        department: event.department,
        yearLabel: event.yearLabel,
        note: event.note,
        courseOfferingId: event.courseOfferingId,
        sectionId: event.sectionId,
        subjectId: event.subjectId,
        instructorId: event.instructorId,
        studentScopeLabel: event.studentScopeLabel,
        repeatRule: event.repeatRule,
        assignedStaffIds: event.assignedStaffIds,
      ),
    );
  }

  void _ensureSeeded() {
    _cache ??= _seedEvents();
    _lookups ??= _buildLookups(_cache!);
  }

  void _rebuildLookups() {
    _lookups = _buildLookups(_cache ?? const <ScheduleEventItem>[]);
  }

  void _replace(ScheduleEventItem item) {
    _cache = [
      for (final current in _cache!)
        if (current.id == item.id) item else current,
    ]..sort((left, right) => left.startAt.compareTo(right.startAt));
  }

  List<ScheduleEventItem> _seedEvents() {
    final subjects = _demoDataService
        .subjects()
        .take(5)
        .toList(growable: false);
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 35));
    final items = <ScheduleEventItem>[];

    var eventIndex = 1;
    for (var dayOffset = 0; dayOffset < 70; dayOffset++) {
      final date = startDate.add(Duration(days: dayOffset));
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }

      final eventsForDay = (dayOffset % 2) + 1;
      for (var j = 0; j < eventsForDay; j++) {
        final subject = subjects[(dayOffset + j) % subjects.length];
        final isAssistantLead = (dayOffset + j).isOdd;
        final instructorName = isAssistantLead
            ? subject.assistant.name
            : subject.doctor.name;
        final instructorId = isAssistantLead
            ? subject.assistant.id
            : subject.doctor.id;

        final type = switch ((dayOffset + j) % 4) {
          0 => ScheduleEventType.lecture,
          1 => ScheduleEventType.quiz,
          2 => ScheduleEventType.exam,
          _ => ScheduleEventType.task,
        };

        final status = date.isBefore(now)
            ? ScheduleEventStatus.completed
            : ScheduleEventStatus.planned;

        final startHour = 8 + (j * 3);
        final start = DateTime(date.year, date.month, date.day, startHour, 0);
        final durationHours = type == ScheduleEventType.exam ? 3 : 2;
        final sectionCode =
            '${subject.department.substring(0, 2).toUpperCase()}-${((dayOffset + j) % 4) + 1}A';

        items.add(
          ScheduleEventItem(
            id: 'SCH-$eventIndex',
            title: '${type.label} - ${subject.code}',
            section: sectionCode,
            subject: subject.name,
            instructor: instructorName,
            location: eventIndex % 5 == 0
                ? 'Hall A${(eventIndex % 4) + 1}'
                : 'Lab ${String.fromCharCode(65 + (eventIndex % 5))}${(eventIndex % 3) + 1}',
            status: status,
            type: type,
            startAt: start,
            endAt: start.add(Duration(hours: durationHours)),
            department: subject.department,
            yearLabel: subject.academicYear,
            note: type == ScheduleEventType.exam
                ? 'Seating plan and invigilation checklist required.'
                : 'Prepared for ${subject.enrolledStudents} enrolled students.',
            courseOfferingId: 'OFF-${subject.id}',
            sectionId: 'SEC-$sectionCode',
            subjectId: subject.id,
            instructorId: instructorId,
            studentScopeLabel:
                '$sectionCode - ${math.max(subject.enrolledStudents - (eventIndex % 10), 24)} students',
            repeatRule: eventIndex < 20
                ? ScheduleRepeatRule.weekly
                : ScheduleRepeatRule.none,
            assignedStaffIds: <String>[
              instructorId,
              if (!isAssistantLead) subject.assistant.id,
            ],
            isSynced: date.isBefore(now),
          ),
        );
        eventIndex++;
      }
    }

    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final conflictDay = weekStart.add(const Duration(days: 2, hours: 10));

    items.addAll([
      ScheduleEventItem(
        id: 'SCH-CONFLICT-1',
        title: 'Algorithms Quiz Window',
        section: 'CS-4A',
        subject: subjects.first.name,
        instructor: subjects.first.doctor.name,
        location: 'Hall C2',
        status: ScheduleEventStatus.planned,
        type: ScheduleEventType.quiz,
        startAt: conflictDay,
        endAt: conflictDay.add(const Duration(hours: 1, minutes: 30)),
        department: subjects.first.department,
        yearLabel: subjects.first.academicYear,
        note: 'Shared hall with another booking to surface conflict detection.',
        courseOfferingId: 'OFF-${subjects.first.id}',
        sectionId: 'SEC-CS-4A',
        subjectId: subjects.first.id,
        instructorId: subjects.first.doctor.id,
        studentScopeLabel: 'CS-4A - 82 students',
        assignedStaffIds: <String>[subjects.first.doctor.id],
        isSynced: true,
      ),
      ScheduleEventItem(
        id: 'SCH-CONFLICT-2',
        title: 'Operating Systems Task Clinic',
        section: 'CS-4A',
        subject: subjects[1].name,
        instructor: subjects.first.doctor.name,
        location: 'Hall C2',
        status: ScheduleEventStatus.planned,
        type: ScheduleEventType.task,
        startAt: conflictDay.add(const Duration(minutes: 30)),
        endAt: conflictDay.add(const Duration(hours: 2)),
        department: subjects.first.department,
        yearLabel: subjects.first.academicYear,
        note: 'This overlaps by instructor, section, and room.',
        courseOfferingId: 'OFF-${subjects[1].id}',
        sectionId: 'SEC-CS-4A',
        subjectId: subjects[1].id,
        instructorId: subjects.first.doctor.id,
        studentScopeLabel: 'CS-4A - 82 students',
        assignedStaffIds: <String>[
          subjects.first.doctor.id,
          subjects.first.assistant.id,
        ],
        isSynced: true,
      ),
    ]);

    items.sort((left, right) => left.startAt.compareTo(right.startAt));
    return List<ScheduleEventItem>.unmodifiable(items);
  }

  ScheduleLookupBundle _buildLookups(List<ScheduleEventItem> events) {
    final subjects = _demoDataService.subjects();
    final staffOptions = _buildStaffOptions(subjects);
    return ScheduleLookupBundle(
      departments: _distinctOptions(
        events.map(
          (event) =>
              ScheduleOption(id: event.department, label: event.department),
        ),
      ),
      years: _distinctOptions(
        events.map(
          (event) =>
              ScheduleOption(id: event.yearLabel, label: event.yearLabel),
        ),
      ),
      subjects: _distinctOptions(
        subjects.map(
          (subject) => ScheduleOption(
            id: subject.id,
            label: subject.name,
            subtitle: subject.code,
          ),
        ),
      ),
      instructors: _distinctOptions(staffOptions),
      sections: _distinctOptions(
        events.map(
          (event) => ScheduleOption(
            id: event.sectionId ?? event.section,
            label: event.section,
            subtitle: '${event.department} - ${event.yearLabel}',
          ),
        ),
      ),
      offerings: _distinctOptions(
        events.map(
          (event) => ScheduleOption(
            id: event.courseOfferingId ?? event.id,
            label: '${event.subject} - ${event.section}',
            subtitle: event.yearLabel,
          ),
        ),
      ),
      staff: _distinctOptions(staffOptions),
    );
  }

  Iterable<ScheduleOption> _buildStaffOptions(
    List<SubjectRecord> subjects,
  ) sync* {
    for (final subject in subjects) {
      yield _staffOptionForMember(subject.doctor, subject.department);
      yield _staffOptionForMember(subject.assistant, subject.department);
    }
  }

  ScheduleOption _staffOptionForMember(
    SubjectStaffMember member,
    String department,
  ) {
    return ScheduleOption(
      id: member.id,
      label: member.name,
      subtitle: '${member.role} - $department',
    );
  }

  List<ScheduleOption> _distinctOptions(Iterable<ScheduleOption> options) {
    final seen = <String>{};
    final resolved = <ScheduleOption>[];
    for (final option in options) {
      if (!seen.add(option.id)) continue;
      resolved.add(option);
    }
    resolved.sort((left, right) => left.label.compareTo(right.label));
    return List<ScheduleOption>.unmodifiable(resolved);
  }
}
