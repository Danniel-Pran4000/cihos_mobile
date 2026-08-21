enum Gender { male, female }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.medicalNo,
    this.nik,
    this.birthDate,
    this.gender,
    this.address,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;

  /// Nomor rekam medis. Accounts created in-app get an `APP-` prefix, which
  /// distinguishes them from numbers issued by the hospital system itself.
  final String? medicalNo;

  /// Nomor Induk Kependudukan — required by most Indonesian hospital systems.
  final String? nik;
  final DateTime? birthDate;
  final Gender? gender;
  final String? address;
  final String? photoUrl;

  /// Builds a user from the `patient` object the API returns.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawDob = json['dob'] as String?;
    final rawGender = (json['gender'] as String?)?.toLowerCase();

    return AppUser(
      id: json['id'].toString(),
      fullName: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      medicalNo: json['medical_no'] as String?,
      nik: json['nik'] as String?,
      birthDate: rawDob == null ? null : DateTime.tryParse(rawDob),
      gender: switch (rawGender) {
        'laki-laki' || 'laki laki' || 'male' => Gender.male,
        'perempuan' || 'female' => Gender.female,
        _ => null,
      },
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': fullName,
      'email': email,
      'phone': phone,
      'medical_no': medicalNo,
      'nik': nik,
      'dob': birthDate?.toIso8601String(),
      'gender': gender == Gender.male
          ? 'laki-laki'
          : (gender == Gender.female ? 'perempuan' : null),
      'address': address,
      'photo_url': photoUrl,
    };
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? nik,
    DateTime? birthDate,
    Gender? gender,
    String? address,
    String? photoUrl,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      medicalNo: medicalNo,
      nik: nik ?? this.nik,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
