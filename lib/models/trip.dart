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
    return Trip(
      id: json['id'],
      status: json['status'],
      originAddress: json['origin_address'],
      destinationAddress: json['destination_address'],
      fare: json['fare'].toDouble(),
      driverId: json['driver_id'],
      passengerId: json['passenger_id'],
    );
  }
}
