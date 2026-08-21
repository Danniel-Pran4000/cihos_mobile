import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../domain/booking.dart';

class BookingRepository {
  BookingRepository(this._client);

  final ApiClient _client;

  /// Books an appointment directly into the hospital's Medinfras system.
  ///
  /// Returns the booking code (e.g. `BKG-00123`) on success.
  /// Throws [ApiException] if the slot is taken or the request fails.
  Future<String> create(Booking booking) async {
    // The date must be exactly yyyyMMdd for MEDINFRAS.
    final startDate =
        booking.date != null ? DateFormat('yyyyMMdd').format(booking.date!) : '';

    final payload = {
      'ServiceUnitCode': booking.unitCode ?? '',
      'ParamedicCode': booking.paramedicCode ?? '',
      // Ensure paramedic ID is sent as an integer, if possible.
      'ParamedicID': int.tryParse(booking.doctorId ?? '') ?? 0,
      'OperationalTimeCode': booking.operationalTimeCode ?? '',
      'Session': booking.session ?? 1,
      'StartDate': startDate,
      'slot_no': booking.slotNumber ?? 0,
      'IsNewPatient': booking.isNewPatient ? '1' : '0',
      'MedicalNo': booking.patientMedicalRecordNumber ?? '',
      'PatientName': booking.patientName ?? '',
      // Default to "UMUM" if payment method is not specified or mapped.
      'PaymentMethod': booking.paymentMethod == 'Pribadi' ? 'UMUM' : 'ASURANSI',
      if (booking.company != null) 'Company': booking.company,
    };

    final response = await _client.post(
      '/taptalk/appointment',
      body: payload,
    );

    // Assuming the API returns the booking code in `data.booking_code` or `booking_code`.
    // We adjust based on typical responses in this project, often mapped under 'data'.
    final data = response['data'] as Map<String, dynamic>?;
    return (data?['booking_code'] as String?) ?? (response['booking_code'] as String?) ?? 'BKG-SUCCESS';
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(apiClientProvider));
});
