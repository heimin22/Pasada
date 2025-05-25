import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/screens/homeScreen.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:pasada_passenger_app/services/driverAssignmentService.dart';
import 'package:pasada_passenger_app/services/driverService.dart';
import 'package:pasada_passenger_app/services/localDatabaseService.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:pasada_passenger_app/main.dart'; // For supabase
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/screens/completedRideScreen.dart';

class BookingManager {
  final HomeScreenPageState _state;

  BookingManager(this._state);

  Future<void> loadActiveBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = prefs.getInt('activeBookingId');
    if (bookingId == null) return;

    _state.bookingService = BookingService();
    final apiBooking =
        await _state.bookingService!.getBookingDetails(bookingId);

    if (apiBooking != null) {
      final status = apiBooking['ride_status'];
      if (status == 'searching' ||
          status == 'assigned' ||
          status == 'ongoing' ||
          status == 'requested') {
        _state.setState(() {
          _state.isBookingConfirmed = true;
          _state.bookingStatus = status;
          _state.selectedPickUpLocation = SelectedLocation(
            apiBooking['pickup_address'],
            LatLng(
              double.parse(apiBooking['pickup_lat'].toString()),
              double.parse(apiBooking['pickup_lng'].toString()),
            ),
          );
          _state.selectedDropOffLocation = SelectedLocation(
            apiBooking['dropoff_address'],
            LatLng(
              double.parse(apiBooking['dropoff_lat'].toString()),
              double.parse(apiBooking['dropoff_lng'].toString()),
            ),
          );
          _state.currentFare = double.parse(apiBooking['fare'].toString());
          _state.selectedPaymentMethod = apiBooking['payment_method'] ?? 'Cash';
        });

        if (apiBooking['driver_id'] != null) {
          await _loadBookingAfterDriverAssignment(bookingId);
        }

        _state.bookingAnimationController.forward();
        _state.driverAssignmentService = DriverAssignmentService();
        _state.driverAssignmentService!.pollForDriverAssignment(
          bookingId,
          (_) => _loadBookingAfterDriverAssignment(bookingId),
          onError: () {},
          onStatusChange: (newStatus) {
            _state.setState(() => _state.bookingStatus = newStatus);
            _fetchAndUpdateBookingDetails(bookingId);
          },
        );
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _state.measureContainers());
        return;
      }
    }

    final localBooking =
        await LocalDatabaseService().getBookingDetails(bookingId);
    if (localBooking == null) {
      await prefs.remove('activeBookingId');
      return;
    }

    final status = localBooking.rideStatus;
    if (status == 'searching' || status == 'assigned' || status == 'ongoing') {
      _state.setState(() {
        _state.isBookingConfirmed = true;
        _state.selectedPickUpLocation = SelectedLocation(
          localBooking.pickupAddress,
          localBooking.pickupCoordinates,
        );
        _state.selectedDropOffLocation = SelectedLocation(
          localBooking.dropoffAddress,
          localBooking.dropoffCoordinates,
        );
        _state.currentFare = localBooking.fare;
      });
      _state.bookingAnimationController.forward();
      final savedMethod = prefs.getString('selectedPaymentMethod');
      if (savedMethod != null && _state.mounted) {
        _state.setState(() => _state.selectedPaymentMethod = savedMethod);
      }
      try {
        final routeResponse = await supabase
            .from('official_routes')
            .select(
                'route_name, origin_lat, origin_lng, destination_lat, destination_lng, intermediate_coordinates, destination_name, polyline_coordinates')
            .eq('officialroute_id', localBooking.routeId)
            .single();
        final Map<String, dynamic> routeMap =
            Map<String, dynamic>.from(routeResponse as Map);
        var inter = routeMap['intermediate_coordinates'];
        if (inter is String) {
          try {
            inter = jsonDecode(inter);
          } catch (_) {}
        }
        routeMap['intermediate_coordinates'] = inter;
        routeMap['origin_coordinates'] = LatLng(
          double.parse(routeMap['origin_lat'].toString()),
          double.parse(routeMap['origin_lng'].toString()),
        );
        routeMap['destination_coordinates'] = LatLng(
          double.parse(routeMap['destination_lat'].toString()),
          double.parse(routeMap['destination_lng'].toString()),
        );
        _state.setState(() => _state.selectedRoute = routeMap);
      } catch (e) {
        debugPrint('Error restoring route: $e');
      }
      _state.mapScreenKey.currentState?.initializeLocation();
      if (_state.selectedRoute != null) {
        _state.mapScreenKey.currentState?.generateRoutePolyline(
          _state.selectedRoute!['intermediate_coordinates'] as List<dynamic>,
          originCoordinates:
              _state.selectedRoute!['origin_coordinates'] as LatLng?,
          destinationCoordinates:
              _state.selectedRoute!['destination_coordinates'] as LatLng?,
          destinationName:
              _state.selectedRoute!['destination_name']?.toString(),
        );
      }
      final user = supabase.auth.currentUser;
      if (user != null) {
        _state.bookingService = BookingService();
        _state.bookingService!.startLocationTracking(user.id);
        _state.driverAssignmentService = DriverAssignmentService();
        _state.driverAssignmentService!.pollForDriverAssignment(
          bookingId,
          (_) => _loadBookingAfterDriverAssignment(bookingId),
          onError: () {},
        );
      }
    } else {
      await prefs.remove('activeBookingId');
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _state.measureContainers());
  }

  Future<void> handleBookingConfirmation() async {
    if (_state.selectedRoute != null &&
        _state.selectedPickUpLocation != null &&
        _state.selectedDropOffLocation != null) {
      final int routeId = _state.selectedRoute!['officialroute_id'] ?? 0;
      final stopsService = StopsService();
      final pickupStop = await stopsService.findClosestStop(
        _state.selectedPickUpLocation!.coordinates,
        routeId,
      );
      final dropoffStop = await stopsService.findClosestStop(
        _state.selectedDropOffLocation!.coordinates,
        routeId,
      );
      if (pickupStop != null && dropoffStop != null) {
        if (dropoffStop.order <= pickupStop.order) {
          Fluttertoast.showToast(
            msg: 'Invalid route: drop-off must be after pick-up.',
          );
          return;
        }
      }
    }

    final user = supabase.auth.currentUser;
    if (user != null && _state.selectedRoute != null) {
      _state.setState(() {
        _state.isBookingConfirmed = true;
        _state.bookingStatus = 'requested';
      });
      _state.bookingAnimationController.forward();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _state.measureContainers());

      _state.bookingService = BookingService();
      final bookingService = _state.bookingService!;
      final int routeId = _state.selectedRoute!['officialroute_id'] ?? 0;
      final bookingResult = await bookingService.createBooking(
        passengerId: user.id,
        routeId: routeId,
        pickupAddress: _state.selectedPickUpLocation?.address ?? 'Unknown',
        pickupCoordinates:
            _state.selectedPickUpLocation?.coordinates ?? const LatLng(0, 0),
        dropoffAddress: _state.selectedDropOffLocation?.address ?? 'Unknown',
        dropoffCoordinates:
            _state.selectedDropOffLocation?.coordinates ?? const LatLng(0, 0),
        paymentMethod: _state.selectedPaymentMethod ?? 'Cash',
        fare: _state.currentFare,
        seatingPreference: _state.seatingPreference.value,
        onDriverAssigned: (details) =>
            _loadBookingAfterDriverAssignment(details.bookingId),
        onStatusChange: (status) {
          _state.setState(() {
            _state.bookingStatus = status;
            if (status == 'cancelled') handleBookingCancellation();
          });
        },
        onTimeout: () {
          showDialog(
            context: _state.context,
            barrierDismissible: false,
            builder: (ctx) => ResponsiveDialog(
              title: 'No Drivers Available',
              content:
                  const Text('Booking cancelled due to no available drivers.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                )
              ],
            ),
          ).then((_) => handleBookingCancellation());
        },
      );

      if (bookingResult.success) {
        final details = bookingResult.booking!; // bookingId, rideStatus, etc.

        // Persist active booking
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('activeBookingId', details.bookingId);
        _state.activeBookingId = details.bookingId;
        _state.setState(() => _state.bookingStatus = details.rideStatus);
        await _fetchAndUpdateBookingDetails(details.bookingId);

        // Start location-tracking for the passenger
        bookingService.startLocationTracking(user.id);

        // Reset driver-assigned flag
        _state.setState(() => _state.isDriverAssigned = false);

        // 4) **Now** start polling for driver assignment
        _state.driverAssignmentService = DriverAssignmentService();
        _state.driverAssignmentService!.pollForDriverAssignment(
          details.bookingId,
          // onDriverAssigned
          (driverData) {
            _loadBookingAfterDriverAssignment(details.bookingId);
          },
          onError: () {
            // optional error callback
          },
          onStatusChange: (newStatus) {
            _state.setState(() => _state.bookingStatus = newStatus);
            _fetchAndUpdateBookingDetails(details.bookingId);
          },
          onTimeout: () {
            showDialog(
              context: _state.context,
              barrierDismissible: false,
              builder: (ctx) => ResponsiveDialog(
                title: 'No Drivers Available',
                content: const Text(
                    'Booking cancelled due to no available drivers.'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  )
                ],
              ),
            ).then((_) => handleBookingCancellation());
          },
        );
      } else {
        // Booking creation failed
        Fluttertoast.showToast(
          msg: bookingResult.errorMessage ?? 'Booking failed',
        );
        handleBookingCancellation();
      }
    } else {
      Fluttertoast.showToast(msg: 'User or route missing.');
      handleBookingCancellation();
    }
  }

  void handleBookingCancellation() {
    _state.driverAssignmentService?.stopPolling();
    _state.bookingService?.stopLocationTracking();
    SharedPreferences.getInstance().then((prefs) async {
      if (_state.activeBookingId != null) {
        await LocalDatabaseService()
            .deleteBookingDetails(_state.activeBookingId!);
      }
      await prefs.remove('activeBookingId');
      await prefs.remove('pickup');
      await prefs.remove('dropoff');
    });
    _state.mapScreenKey.currentState?.clearAll();
    _state.setState(() {
      _state.isBookingConfirmed = false;
      _state.isDriverAssigned = false;
      _state.activeBookingId = null;
      _state.selectedPickUpLocation = null;
      _state.selectedDropOffLocation = null;
      _state.selectedRoute = null;
    });
    _state.bookingAnimationController.reverse();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _state.measureContainers());
  }

  void _updateDriverDetails(Map<String, dynamic> driverData) {
    if (!_state.mounted) return;
    var driver = driverData['driver'];
    if (driver == null) {
      debugPrint(
          "BookingManager: _updateDriverDetails received null for driverData['driver']");
      _state.setState(() {
        _state.isDriverAssigned = false;
      });
      return;
    }
    if (driver is List && driver.isNotEmpty) {
      driver = driver[0];
      debugPrint(
          "BookingManager: _updateDriverDetails picked first driver from list.");
    } else if (driver is List && driver.isEmpty) {
      debugPrint(
          "BookingManager: _updateDriverDetails received an empty list for driverData['driver']");
      _state.setState(() {
        _state.isDriverAssigned = false;
      });
      return;
    }

    if (driver is! Map<String, dynamic>) {
      debugPrint(
          "BookingManager: _updateDriverDetails - 'driver' variable is not a Map. Actual type: \${driver.runtimeType}, Value: \$driver");
      _state.setState(() {
        _state.isDriverAssigned = false;
      });
      return;
    }

    debugPrint(
        "BookingManager: Processing driver map in _updateDriverDetails: \$driver");

    _state.setState(() {
      _state.driverName =
          _extractField(driver, ['full_name', 'name', 'driver_name']);
      _state.plateNumber = _extractField(
          driver, ['plate_number', 'plateNumber', 'vehicle_plate', 'plate']);
      _state.phoneNumber = _extractField(driver, [
        'driver_number',
        'phone_number',
        'phoneNumber',
        'contact_number',
        'phone'
      ]);
      _state.isDriverAssigned = (_state.driverName.isNotEmpty &&
          _state.driverName != 'Driver' &&
          _state.driverName != 'Not Available');
      _state.bookingStatus = 'accepted';

      debugPrint(
          "BookingManager: _updateDriverDetails SET state - Driver Name: \${_state.driverName}, Plate: \${_state.plateNumber}, Phone: \${_state.phoneNumber}, Is Assigned: \${_state.isDriverAssigned}");
    });
  }

  String _extractField(dynamic data, List<String> keys) {
    if (data is! Map) return '';
    for (var key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key].toString();
      }
    }
    return '';
  }

  Future<void> _fetchAndUpdateBookingDetails(int bookingId) async {
    _state.bookingService ??= BookingService();
    final details = await _state.bookingService!.getBookingDetails(bookingId);
    if (details != null && _state.mounted) {
      if (details['ride_status'] == 'completed') {
        // Dispose booking UI containers before showing completion screen
        handleBookingCancellation();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(_state.context).push(
            MaterialPageRoute(
              builder: (_) => CompletedRideScreen(arrivedTime: DateTime.now()),
            ),
          );
        });
        return;
      }
      _state.setState(() {
        _state.bookingStatus = details['ride_status'] ?? 'requested';
        if (details['fare'] != null) {
          _state.currentFare =
              double.tryParse(details['fare'].toString()) ?? _state.currentFare;
        }
        if (details['payment_method'] != null) {
          _state.selectedPaymentMethod = details['payment_method'];
        }
      });
      if (details['driver_id'] != null) {
        await _loadBookingAfterDriverAssignment(bookingId);
      }
    }
  }

  Future<void> _loadBookingAfterDriverAssignment(int bookingId) async {
    _state.driverAssignmentService
        ?.fetchBookingDetails(bookingId)
        .then((bookingData) {
      if (bookingData != null) {
        final driverId = bookingData['driver_id'];
        if (driverId != null) {
          DriverService()
              .getDriverDetailsByBooking(bookingId)
              .then((driverDetails) {
            if (driverDetails != null) {
              _updateDriverDetails(driverDetails);
            } else {
              DriverService()
                  .getDriverDetails(driverId.toString())
                  .then((directDetails) {
                if (directDetails != null) {
                  _updateDriverDetails(directDetails);
                } else {
                  _fetchDriverDetailsDirectlyFromDB(bookingId);
                }
              });
            }
          });
        } else {
          _fetchDriverDetailsDirectlyFromDB(bookingId);
        }
      } else {
        _fetchDriverDetailsDirectlyFromDB(bookingId);
      }
    });
  }

  Future<void> _fetchDriverDetailsDirectlyFromDB(int bookingId) async {
    try {
      final booking = await supabase
          .from('bookings')
          .select('driver_id')
          .eq('booking_id', bookingId)
          .single();
      if (!booking.containsKey('driver_id')) return;
      final driverId = booking['driver_id'];
      final driver = await supabase
          .from('driverTable')
          .select('driver_id, full_name, driver_number, vehicle_id')
          .eq('driver_id', driverId)
          .single();
      String plate = 'Unknown';
      if (driver.containsKey('vehicle_id') && driver['vehicle_id'] != null) {
        final vehicle = await supabase
            .from('vehicleTable')
            .select('plate_number')
            .eq('vehicle_id', driver['vehicle_id'])
            .single();
        if (vehicle.containsKey('plate_number')) {
          plate = vehicle['plate_number'];
        }
      }
      _state.setState(() {
        _state.driverName = driver['full_name'] ?? 'Driver';
        _state.phoneNumber = driver['driver_number'] ?? '';
        _state.plateNumber = plate;
        _state.isDriverAssigned = true;
        _state.bookingStatus = 'accepted';
      });
    } catch (e) {
      debugPrint('DB Query Error: $e');
    }
  }
}
