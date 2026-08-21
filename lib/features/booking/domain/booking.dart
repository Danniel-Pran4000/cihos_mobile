/// Which kind of consultation a booking is for. The two share every screen in
/// the flow; only copy, lead time, and the doctors on offer differ.
enum BookingKind { appointment, videoCall }

extension BookingKindCopy on BookingKind {
  String get searchTitle => switch (this) {
    BookingKind.appointment => 'Buat Janji Temu',
    BookingKind.videoCall => 'Buat Video Call',
  };

  String get scheduleTitle => switch (this) {
    BookingKind.appointment => 'Pilih Jadwal Janji Temu',
    BookingKind.videoCall => 'Pilih Jadwal Video Call',
  };

  String get label => switch (this) {
    BookingKind.appointment => 'Janji Temu',
    BookingKind.videoCall => 'Video Call',
  };

  String get guideLabel => switch (this) {
    BookingKind.appointment => 'Perlu bantuan? Lihat Panduan Janji Temu',
    BookingKind.videoCall => 'Perlu bantuan? Lihat Panduan Video Call',
  };

  String get datePlaceholder => switch (this) {
    BookingKind.appointment => 'Pilih Tanggal Janji Temu',
    BookingKind.videoCall => 'Pilih Tanggal Video Call',
  };

  String get searchAction => switch (this) {
    BookingKind.appointment => 'Cari Jadwal Janji Temu',
    BookingKind.videoCall => 'Cari Jadwal Video Call',
  };

  /// How far ahead the schedule opens, per the design notes.
  int get leadDays => switch (this) {
    BookingKind.appointment => 30,
    BookingKind.videoCall => 7,
  };

  String get leadTimeNote => switch (this) {
    BookingKind.appointment =>
      'Jadwal Temu Dokter dapat dipilih dari 30 hari sampai 1 jam sebelum '
          'jadwal dokter praktik berakhir.',
    BookingKind.videoCall =>
      'Jadwal Video Call Dokter dapat dipilih dari 7 hari sampai 1 jam '
          'sebelum slot telekonsultasi dimulai.',
  };
}

/// A patient the account can book for.
class BookingPatient {
  const BookingPatient({
    required this.name,
    required this.medicalRecordNumber,
  });

  final String name;
  final String medicalRecordNumber;
}

/// A bookable slot in a doctor's day.
class BookingSlot {
  const BookingSlot({
    required this.start,
    required this.end,
    this.session,
    this.slotNumber,
    this.operationalTimeCode,
    this.isAvailable = true,
  });

  final DateTime start;
  final DateTime end;
  final int? session;
  final int? slotNumber;
  final String? operationalTimeCode;
  final bool isAvailable;

  String get label {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)} - '
        '${two(end.hour)}:${two(end.minute)}';
  }
}

/// What the patient has chosen so far.
class Booking {
  const Booking({
    required this.kind,
    this.doctorName,
    this.doctorId,
    this.paramedicCode,
    this.specialty,
    this.unitCode,
    this.date,
    this.slot,
    this.slotNumber,
    this.session,
    this.operationalTimeCode,
    this.patientName,
    this.patientMedicalRecordNumber,
    this.isNewPatient = false,
    this.paymentMethod,
    this.company,
  });

  final BookingKind kind;
  final String? doctorName;
  final String? doctorId;
  final String? paramedicCode;
  final String? specialty;
  final String? unitCode;
  final DateTime? date;
  final BookingSlot? slot;
  final int? slotNumber;
  final int? session;
  final String? operationalTimeCode;

  final String? patientName;
  final String? patientMedicalRecordNumber;
  final bool isNewPatient;

  /// "Pribadi" or "Asuransi/Perusahaan".
  final String? paymentMethod;
  final String? company;

  /// Search needs at least one of the three criteria filled in.
  bool get hasSearchCriteria =>
      (doctorName?.isNotEmpty ?? false) ||
      (specialty?.isNotEmpty ?? false) ||
      date != null;

  Booking copyWith({
    String? doctorName,
    String? doctorId,
    String? paramedicCode,
    String? specialty,
    String? unitCode,
    DateTime? date,
    BookingSlot? slot,
    int? slotNumber,
    int? session,
    String? operationalTimeCode,
    String? patientName,
    String? patientMedicalRecordNumber,
    bool? isNewPatient,
    String? paymentMethod,
    String? company,
    bool clearSlot = false,
  }) {
    return Booking(
      kind: kind,
      doctorName: doctorName ?? this.doctorName,
      doctorId: doctorId ?? this.doctorId,
      paramedicCode: paramedicCode ?? this.paramedicCode,
      specialty: specialty ?? this.specialty,
      unitCode: unitCode ?? this.unitCode,
      date: date ?? this.date,
      slot: clearSlot ? null : (slot ?? this.slot),
      slotNumber: clearSlot ? null : (slotNumber ?? this.slotNumber),
      session: clearSlot ? null : (session ?? this.session),
      operationalTimeCode: clearSlot ? null : (operationalTimeCode ?? this.operationalTimeCode),
      patientName: patientName ?? this.patientName,
      patientMedicalRecordNumber: patientMedicalRecordNumber ?? this.patientMedicalRecordNumber,
      isNewPatient: isNewPatient ?? this.isNewPatient,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      company: company ?? this.company,
    );
  }
}

abstract final class BookingOptions {
  /// Every specialty the picker offers, with the duplicates the Figma list
  /// carries removed so the same poli cannot appear twice.
  static final specialties = _rawSpecialties.toSet().toList();

  /// The list exactly as the design gives it.
  static const _rawSpecialties = [
    'Andrologi',
    'Alergi',
    'Mata',
    'Penyakit Dalam',
    'Gigi & Kesehatan Mulut',
    'Jiwa',
    'Paru',
    'Syaraf',
    'Radiologi',
    'Penyakit Dalam',
    'Kulit & Kelamin',
    'Radiologi',
    'THT-KL',
    'Bedah Anak',
    'Bedah Digestif',
    'Bedah Onkologi',
    'Bedah Orthopedi & Traumatologi',
    'Bedah Plastik',
    'Bedah Saraf',
    'Bedah Thoraks & Kardiovaskular',
    'Bedah Umum',
    'Bedah Urologi',
  ];

  static const paymentMethods = ['Pribadi', 'Asuransi/Perusahaan'];

  static const companies = [
    'Ciputra Hospital Surabaya',
    'BPJS Kesehatan',
    'Prudential',
    'Allianz',
    'AXA Mandiri',
  ];

  /// Patients already on the account, plus the family members it covers.
  static const patients = [
    BookingPatient(name: 'ANDRI (Suami)', medicalRecordNumber: '010304596'),
    BookingPatient(name: 'DEWI (Saudara)', medicalRecordNumber: '01098895'),
    BookingPatient(name: 'PUTRI (Anak)', medicalRecordNumber: '01023456'),
    BookingPatient(name: 'KARTIKA (Saudara)', medicalRecordNumber: '01076548'),
    BookingPatient(name: 'BAYU (Ayah)', medicalRecordNumber: '01076528'),
    BookingPatient(name: 'OLIVIA (Ibu)', medicalRecordNumber: '01049283'),
    BookingPatient(
      name: 'NADILA (Diri Sendiri)',
      medicalRecordNumber: '01034986',
    ),
  ];

  static List<BookingSlot> slotsFor(DateTime date) {
    return [
      _slot(date, 12, 0, 12, 15),
      _slot(date, 12, 20, 12, 35),
      _slot(date, 13, 0, 13, 15),
      _slot(date, 13, 20, 13, 35),
      _slot(date, 14, 0, 14, 15, isAvailable: false),
      _slot(date, 14, 20, 14, 35),
    ];
  }

  static BookingSlot _slot(
    DateTime day,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute, {
    bool isAvailable = true,
  }) {
    return BookingSlot(
      start: DateTime(day.year, day.month, day.day, startHour, startMinute),
      end: DateTime(day.year, day.month, day.day, endHour, endMinute),
      isAvailable: isAvailable,
    );
  }

  /// Whether [day] falls inside the booking window for [kind].
  static bool isBookable(DateTime day, BookingKind kind) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);
    final daysAhead = target.difference(today).inDays;

    return daysAhead >= 0 && daysAhead <= kind.leadDays;
  }

  /// Doctors do not hold clinics on Sundays.
  static bool isPractisingDay(DateTime day) => day.weekday != DateTime.sunday;
}
