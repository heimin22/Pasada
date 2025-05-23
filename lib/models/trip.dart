class Trip {
  final String id;
  final String status;
  final String originAddress;
  final String destinationAddress;
  final double fare;
  final String? driverId;
  final String passengerId;

  Trip({
    required this.id,
    required this.status,
    required this.originAddress,
    required this.destinationAddress,
    required this.fare,
    this.driverId,
    required this.passengerId,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Create a safe copy of the JSON data
    final safeJson = Map<String, dynamic>.from(json);

    // Ensure coordinate fields are properly handled
    final List<String> coordinateFields = [
      'pickup_lat',
      'pickup_lng',
      'dropoff_lat',
      'dropoff_lng'
    ];

    for (final field in coordinateFields) {
      if (safeJson.containsKey(field)) {
        if (safeJson[field] == null || safeJson[field] == 'null') {
          safeJson[field] = 0.0;
        } else if (safeJson[field] is String) {
          // Convert string coordinates to double
          safeJson[field] = double.tryParse(safeJson[field]) ?? 0.0;
        }
      }
    }

    return Trip(
      id: safeJson['booking_id'].toString(),
      status: safeJson['ride_status'] ?? '',
      originAddress: safeJson['pickup_address'] ?? '',
      destinationAddress: safeJson['dropoff_address'] ?? '',
      fare: (safeJson['fare'] is num)
          ? safeJson['fare'].toDouble()
          : double.tryParse(safeJson['fare']?.toString() ?? '0') ?? 0.0,
      driverId: safeJson['driver_id']?.toString(),
      passengerId: safeJson['passenger_id'] ?? '',
    );
  }
}
