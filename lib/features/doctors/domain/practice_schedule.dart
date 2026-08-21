/// One weekly practice session: which clinic, which day, which hours.
class PracticeSchedule {
  const PracticeSchedule({
    required this.unitCode,
    required this.unitName,
    required this.dayNumber,
    required this.timeLabel,
    this.operationalTimeCode = '',
    this.roomCode,
    this.windows = const [],
  });

  factory PracticeSchedule.fromJson(Map<String, dynamic> json) {
    final rawWindows = json['windows'];
    return PracticeSchedule(
      unitCode: json['service_unit_code'] as String? ?? '',
      unitName: json['service_unit_name'] as String? ?? '',
      // The API uses ISO weekday numbering: 1 = Monday.
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 0,
      timeLabel: json['operational_time_name'] as String? ?? '',
      operationalTimeCode: json['operational_time_code'] as String? ?? '',
      roomCode: json['room_code'] as String?,
      windows: rawWindows is List
          ? rawWindows
                .whereType<Map>()
                .map((w) => PracticeWindow.fromJson(w.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }

  final String unitCode;
  final String unitName;

  /// ISO weekday: 1 = Monday … 7 = Sunday.
  final int dayNumber;

  /// Human-readable range, e.g. `19:00 - 20:00`.
  final String timeLabel;

  /// Medinfras operational time code, e.g. `OT-020`.
  final String operationalTimeCode;

  final String? roomCode;
  final List<PracticeWindow> windows;
}

/// A bookable window inside a practice session.
class PracticeWindow {
  const PracticeWindow({
    required this.session,
    required this.start,
    required this.end,
  });

  factory PracticeWindow.fromJson(Map<String, dynamic> json) => PracticeWindow(
    session: (json['session'] as num?)?.toInt() ?? 1,
    start: json['start'] as String? ?? '',
    end: json['end'] as String? ?? '',
  );

  final int session;

  /// `HH:mm`.
  final String start;
  final String end;
}

/// A queue position the patient can take on a given date.
///
/// The hospital books by queue number within a session rather than by exact
/// minute, so a "slot" is a number plus the session's time range — not a
/// fifteen-minute appointment.
class BookableSlot {
  const BookableSlot({
    required this.session,
    required this.number,
    required this.start,
    required this.end,
    this.room,
  });

  final int session;

  /// Queue number within the session.
  final int number;

  final String start;
  final String end;
  final String? room;

  String get timeLabel => '$start - $end';
}

/// The sessions available for one doctor on one date.
class DaySlots {
  const DaySlots({required this.date, required this.slots});

  factory DaySlots.fromJson(Map<String, dynamic> json) {
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    final sessions = json['sessions'];
    final slots = <BookableSlot>[];

    if (sessions is List) {
      for (final raw in sessions.whereType<Map>()) {
        final session = raw.cast<String, dynamic>();
        final available = session['available'];
        if (available is! List) continue;

        for (final entry in available.whereType<Map>()) {
          slots.add(
            BookableSlot(
              session: (session['session'] as num?)?.toInt() ?? 1,
              number: (entry['no'] as num?)?.toInt() ?? 0,
              start: session['start'] as String? ?? '',
              end: session['end'] as String? ?? '',
              room: session['room'] as String?,
            ),
          );
        }
      }
    }

    return DaySlots(date: date, slots: slots);
  }

  final DateTime date;
  final List<BookableSlot> slots;

  bool get isEmpty => slots.isEmpty;
}
