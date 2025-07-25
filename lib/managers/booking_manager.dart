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
import 'package:pasada_passenger_app/services/map_location_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/screens/completedRideScreen.dart';
import 'dart:async';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:pasada_passenger_app/services/eta_service.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';
import 'dart:math';

class BookingManager {
  final HomeScreenPageState _state;
  bool _acceptedNotified = false;
  bool _progressNotificationStarted = false;
  double? _initialDistanceToDropoff;
  Timer? _completionTimer; // Polling for ride completion

  BookingManager(this._state);

  /// Calculates the distance in meters between two latitude/longitude points.
  double _calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371000; // Earth's radius in meters
    final lat1 = p1.latitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> loadActiveBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = prefs.getInt('activeBookingId');
    if (bookingId == null) return;

    _state.bookingService = BookingService();
    final apiBooking =
        await _state.bookingService!.getBookingDetails(bookingId);

    if (apiBooking != null) {
      final status = apiBooking['ride_status'];
      if (status == 'requested' ||
          status == 'accepted' ||
          status == 'ongoing') {
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
          _state.activeBookingId = bookingId;
          if (apiBooking['seat_type'] != null) {
            _state.seatingPreference.value = apiBooking['seat_type'].toString();
          }
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
            debugPrint(
                "[BookingManager] loadActiveBooking->pollForDriverAssignment->onStatusChange: Received newStatus '$newStatus' for booking $bookingId. Current _state.bookingStatus is '${_state.bookingStatus}'. Mounted: ${_state.mounted}");
            if (_state.mounted) {
              if (newStatus == 'accepted' && !_acceptedNotified) {
                _acceptedNotified = true;
                NotificationService.showNotification(
                  title: 'Driver Assigned',
                  body: 'Your driver has accepted your ride and is on the way!',
                );
              }
              if (newStatus == 'ongoing' && !_progressNotificationStarted) {
                _progressNotificationStarted = true;
                NotificationService.showRideProgressNotification(
                  progress: 0,
                  maxProgress: 100,
                );
              }
              _state.setState(() => _state.bookingStatus = newStatus);
              debugPrint(
                  "[BookingManager] loadActiveBooking->pollForDriverAssignment->onStatusChange->setState: _state.bookingStatus is now '${_state.bookingStatus}' for booking $bookingId.");
              // Call _fetchAndUpdateBookingDetails for relevant status changes
              if (newStatus == 'accepted' ||
                  newStatus == 'ongoing' ||
                  newStatus == 'completed' ||
                  newStatus == 'requested') {
                debugPrint(
                    "[BookingManager] loadActiveBooking->pollForDriverAssignment->onStatusChange: Status is relevant ('$newStatus'), calling _fetchAndUpdateBookingDetails for $bookingId.");
                _fetchAndUpdateBookingDetails(bookingId);
              } else {
                debugPrint(
                    "[BookingManager] loadActiveBooking->pollForDriverAssignment->onStatusChange: Status '$newStatus' does not trigger _fetchAndUpdateBookingDetails.");
              }
            }
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
    if (status == 'requested' || status == 'accepted' || status == 'ongoing') {
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
        _state.activeBookingId = bookingId;
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
      MapLocationService().initialize((pos) {
        _state.mapScreenKey.currentState
            ?.updateDriverLocation(pos, _state.bookingStatus);
      });
      if (_state.selectedRoute != null) {
        final polyService = PolylineService();
        final coords = polyService.generateAlongRoute(
          _state.selectedRoute!['origin_coordinates'] as LatLng,
          _state.selectedRoute!['destination_coordinates'] as LatLng,
          _state.selectedRoute!['intermediate_coordinates'] as List<LatLng>,
        );
        _state.mapScreenKey.currentState?.animateRouteDrawing(
          const PolylineId('route'),
          coords,
          const Color(0xFFFFCE21),
          8,
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
      debugPrint(
          'BookingManager: sending seat_type: ${_state.seatingPreference.value}');
      final bookingResult = await bookingService.createBooking(
        passengerId: user.id,
        routeId: routeId,
        pickupAddress: _state.selectedPickUpLocation!.address,
        pickupCoordinates: _state.selectedPickUpLocation!.coordinates,
        dropoffAddress: _state.selectedDropOffLocation!.address,
        dropoffCoordinates: _state.selectedDropOffLocation!.coordinates,
        paymentMethod: _state.selectedPaymentMethod ?? 'Cash',
        fare: _state.currentFare,
        seatingPreference: _state.seatingPreference.value,
        onDriverAssigned: (details) =>
            _loadBookingAfterDriverAssignment(details.bookingId),
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
          (driverData) {
            _loadBookingAfterDriverAssignment(details.bookingId);
          },
          onError: () {},
          onStatusChange: (newStatus) {
            if (_state.mounted) {
              if (newStatus == 'accepted' && !_acceptedNotified) {
                _acceptedNotified = true;
                NotificationService.showNotification(
                  title: 'Yun, may driver ka na boss!',
                  body: 'Your driver has accepted your ride and is on the way!',
                );
              }
              if (newStatus == 'ongoing' && !_progressNotificationStarted) {
                _progressNotificationStarted = true;
                NotificationService.showRideProgressNotification(
                  progress: 0,
                  maxProgress: 100,
                );
              }
              _state.setState(() => _state.bookingStatus = newStatus);
              if (newStatus == 'accepted' ||
                  newStatus == 'ongoing' ||
                  newStatus == 'completed' ||
                  newStatus == 'requested') {
                _fetchAndUpdateBookingDetails(details.bookingId);
              }
            }
          },
          onTimeout: () {
            showDialog(
              context: _state.context,
              barrierDismissible: false,
              builder: (ctx) => ResponsiveDialog(
                title: 'No Drivers Available',
                content:
                    const Text('Yun nga lang, walang driver. Hehe sorry boss.'),
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
    _acceptedNotified = false;
    _progressNotificationStarted = false;
    NotificationService.cancelRideProgressNotification();
    _completionTimer?.cancel();
    _completionTimer = null;
    _state.driverAssignmentService?.stopPolling();
    _state.bookingService?.stopLocationTracking();

    final currentBookingId = _state.activeBookingId;

    SharedPreferences.getInstance().then((prefs) async {
      if (currentBookingId != null) {
        await LocalDatabaseService().deleteBookingDetails(currentBookingId);
      }
      await prefs.remove('activeBookingId');
      await prefs.remove('pickup');
      await prefs.remove('dropoff');
    });

    if (_state.mounted) {
      _state.mapScreenKey.currentState?.clearAll();
      _state.setState(() {
        _state.isBookingConfirmed = false;
        _state.isDriverAssigned = false;
        _state.activeBookingId = null;
        _state.selectedPickUpLocation = null;
        _state.selectedDropOffLocation = null;
        _state.selectedRoute = null;
        _state.bookingStatus = ''; // Reset booking status
      });
      _state.bookingAnimationController.reverse();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_state.mounted) {
          _state.measureContainers();
        }
      });
    }
  }

  void _updateDriverDetails(Map<String, dynamic> driverData) async {
    if (!_state.mounted) {
      debugPrint(
          "[BookingManager] _updateDriverDetails: Entered but state not mounted. Bailing out.");
      return;
    }
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
        "BookingManager: Processing driver map in _updateDriverDetails: \\$driver");
    debugPrint("BookingManager: driver keys: \\${driver.keys}");

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

      debugPrint(
          "[BookingManager] Inside _updateDriverDetails->setState: bookingStatus set to ${_state.bookingStatus}, isDriverAssigned set to ${_state.isDriverAssigned}, Driver: ${_state.driverName} for activeBookingId ${_state.activeBookingId}");
    });

    // Extract driver's current_location from driver details RPC
    dynamic currentLoc = driver['current_location'];
    LatLng? driverLatLng;
    if (currentLoc != null) {
      // GeoJSON format: { type: 'Point', coordinates: [lon, lat] }
      if (currentLoc is Map && currentLoc['coordinates'] is List) {
        final coords = List.from(currentLoc['coordinates']);
        driverLatLng = LatLng(coords[1] as double, coords[0] as double);
      }
      // WKT format: 'POINT(lon lat)'
      else if (currentLoc is String) {
        final match =
            RegExp(r"POINT\(([-\d\.]+) ([-\d\.]+)\)").firstMatch(currentLoc);
        if (match != null) {
          final lon = double.parse(match.group(1)!);
          final lat = double.parse(match.group(2)!);
          driverLatLng = LatLng(lat, lon);
        }
      }
    }
    if (driverLatLng != null) {
      _state.mapScreenKey.currentState
          ?.updateDriverLocation(driverLatLng, _state.bookingStatus);
      // Update ride progress notification
      final dropoff = _state.selectedDropOffLocation?.coordinates;
      if (dropoff != null) {
        _initialDistanceToDropoff ??= _calculateDistance(driverLatLng, dropoff);
        final currentDistance = _calculateDistance(driverLatLng, dropoff);
        final int progress = (((_initialDistanceToDropoff! - currentDistance) /
                    _initialDistanceToDropoff!) *
                100)
            .clamp(0, 100)
            .round();
        // Compute ETA using external service
        try {
          final etaService = ETAService();
          final etaResp = await etaService.getETAWithGemini({
            'origin': {
              'lat': driverLatLng.latitude,
              'lng': driverLatLng.longitude,
            },
            'destination': {
              'lat': dropoff.latitude,
              'lng': dropoff.longitude,
            },
          });
          final int etaSec = (etaResp['eta_seconds'] as int?) ?? 0;
          final int etaMin = (etaSec / 60).ceil();
          final String etaTitle =
              etaMin > 0 ? 'Arriving at $etaMin min' : 'Arriving';
          await NotificationService.showRideProgressNotification(
            progress: progress,
            maxProgress: 100,
            title: etaTitle,
          );
        } catch (e) {
          await NotificationService.showRideProgressNotification(
            progress: progress,
            maxProgress: 100,
            title: 'Arriving',
          );
        }
      }
    }

    // Start polling for completion after acceptance
    if (_state.activeBookingId != null) {
      debugPrint(
          "[BookingManager] _updateDriverDetails: Condition met to start polling. ActiveBookingID: \\${_state.activeBookingId}, IsDriverAssigned: \\${_state.isDriverAssigned}. Calling _startCompletionPolling.");
      _startCompletionPolling(_state.activeBookingId!);
    } else {
      debugPrint(
          "[BookingManager] _updateDriverDetails: Condition NOT MET to start polling. activeBookingId is null. IsDriverAssigned: \\${_state.isDriverAssigned}.");
    }
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

    if (!_state.mounted) {
      debugPrint(
          "[BookingManager] _fetchAndUpdateBookingDetails: State not mounted for booking ID $bookingId at entry. Bailing out.");
      return;
    }
    debugPrint(
        "[BookingManager] _fetchAndUpdateBookingDetails: Fetching for booking ID $bookingId. Mounted: ${_state.mounted}");

    final details = await _state.bookingService!.getBookingDetails(bookingId);
    if (!_state.mounted) {
      // Check again after await
      debugPrint(
          "[BookingManager] _fetchAndUpdateBookingDetails: State not mounted for booking ID $bookingId after getBookingDetails. Bailing out.");
      return;
    }

    if (details != null) {
      debugPrint(
          "[BookingManager] _fetchAndUpdateBookingDetails: Details for booking ID $bookingId: $details");
      if (details['ride_status'] == 'completed') {
        debugPrint(
            "[BookingManager] _fetchAndUpdateBookingDetails: Ride COMPLETED for booking ID $bookingId. Navigating.");
        await _handleRideCompletionNavigationAndCleanup();
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
        // Update seating preference if provided
        if (details['seat_type'] != null) {
          _state.seatingPreference.value = details['seat_type'].toString();
        }
      });
      if (details['driver_id'] != null) {
        debugPrint(
            "[BookingManager] _fetchAndUpdateBookingDetails: driver_id ${details['driver_id']} found for booking $bookingId. Calling _loadBookingAfterDriverAssignment.");
        await _loadBookingAfterDriverAssignment(bookingId);
      } else {
        debugPrint(
            "[BookingManager] _fetchAndUpdateBookingDetails: No driver_id found for booking $bookingId.");
      }
    }
  }

  Future<void> _loadBookingAfterDriverAssignment(int bookingId) async {
    debugPrint(
        "[BookingManager] _loadBookingAfterDriverAssignment: Entered for booking ID $bookingId");
    // Try fetching full driver details (including current_location) via RPC
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final result =
            await supabase.rpc('get_driver_details_by_booking', params: {
          'p_booking_id': bookingId,
          'p_user_id': user.id,
        }).single() as Map<String, dynamic>?;
        if (result != null) {
          _updateDriverDetails({'driver': result});
          return;
        }
      } catch (e) {
        debugPrint(
            "[BookingManager] Error fetching driver details via RPC: $e");
      }
    }
    // Fallback to existing fetchBookingDetails logic
    _state.driverAssignmentService
        ?.fetchBookingDetails(bookingId)
        .then((bookingData) {
      if (bookingData != null) {
        debugPrint(
            "[BookingManager] _loadBookingAfterDriverAssignment: Fetched bookingData for $bookingId: $bookingData");
        final driverId = bookingData['driver_id'];
        if (driverId != null) {
          debugPrint(
              "[BookingManager] _loadBookingAfterDriverAssignment: driver_id $driverId found. Fetching driver details via getDriverDetailsByBooking.");
          DriverService()
              .getDriverDetailsByBooking(bookingId)
              .then((driverDetails) {
            if (driverDetails != null) {
              debugPrint(
                  "[BookingManager] _loadBookingAfterDriverAssignment: Got driverDetails via getDriverDetailsByBooking for $bookingId: $driverDetails. Calling _updateDriverDetails.");
              _updateDriverDetails(driverDetails);
            } else {
              debugPrint(
                  "[BookingManager] _loadBookingAfterDriverAssignment: getDriverDetailsByBooking returned null for $bookingId. Trying getDriverDetails with driverId $driverId.");
              DriverService()
                  .getDriverDetails(driverId.toString())
                  .then((directDetails) {
                if (directDetails != null) {
                  debugPrint(
                      "[BookingManager] _loadBookingAfterDriverAssignment: Got directDetails for driver $driverId: $directDetails. Calling _updateDriverDetails.");
                  _updateDriverDetails(directDetails);
                } else {
                  debugPrint(
                      "[BookingManager] _loadBookingAfterDriverAssignment: getDriverDetails also returned null for driver $driverId. Fetching directly from DB for booking $bookingId.");
                  _fetchDriverDetailsDirectlyFromDB(bookingId);
                }
              });
            }
          });
        } else {
          debugPrint(
              "[BookingManager] _loadBookingAfterDriverAssignment: No driver_id in bookingData for $bookingId. Fetching directly from DB.");
          _fetchDriverDetailsDirectlyFromDB(bookingId);
        }
      } else {
        debugPrint(
            "[BookingManager] _loadBookingAfterDriverAssignment: fetchBookingDetails returned null for $bookingId. Fetching directly from DB.");
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
      });
      // Start polling for completion when using direct DB fetch as well
      if (_state.activeBookingId != null) {
        debugPrint(
            "[BookingManager] _fetchDriverDetailsDirectlyFromDB: Driver details restored. Starting completion polling for booking ID $bookingId.");
        _startCompletionPolling(bookingId);
      }
    } catch (e) {
      debugPrint('DB Query Error: $e');
    }
  }

  /// Poll the booking status every 10 seconds until it's completed
  void _startCompletionPolling(int bookingId) {
    if (_completionTimer != null) return; // Already polling
    debugPrint(
        "[BookingManager] _startCompletionPolling: Starting for booking ID $bookingId");
    _completionTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      debugPrint(
          "[BookingManager] Polling for completion for booking ID $bookingId...");
      try {
        final details =
            await _state.bookingService?.getBookingDetails(bookingId);
        if (details != null) {
          debugPrint(
              "[BookingManager] Polled details for booking ID $bookingId: $details");
          final status = details['ride_status'];
          // If ride ongoing, update driver location & polyline
          if (status == 'ongoing') {
            debugPrint(
                "[BookingManager] Ride ongoing: refreshing driver location for booking ID $bookingId");
            final driverDetails =
                await DriverService().getDriverDetailsByBooking(bookingId);
            if (driverDetails != null) {
              _updateDriverDetails(driverDetails);
            }
          }
          // When completed, navigate and cleanup
          if (status == 'completed') {
            debugPrint(
                "[BookingManager] Ride COMPLETED for booking ID $bookingId. Status: ${details['ride_status']}");
            timer.cancel(); // Stop this specific timer instance.
            await _handleRideCompletionNavigationAndCleanup();
          } else {
            debugPrint(
                "[BookingManager] Ride NOT YET COMPLETED for booking ID $bookingId. Status: $status");
          }
        } else {
          debugPrint(
              "[BookingManager] Polling for booking ID $bookingId returned null details.");
        }
      } catch (e) {
        debugPrint(
            '[BookingManager] Error polling for completion for booking ID $bookingId: $e');
      }
    });
  }

  Future<void> _handleRideCompletionNavigationAndCleanup() async {
    _acceptedNotified = false;
    _progressNotificationStarted = false;
    NotificationService.cancelRideProgressNotification();
    if (!_state.mounted) return;

    debugPrint(
        "[BookingManager] _handleRideCompletionNavigationAndCleanup: Entered for booking ID ${_state.activeBookingId}");

    final BuildContext safeContext = _state.context;
    final int? completedBookingId = _state.activeBookingId;

    _completionTimer?.cancel();
    _completionTimer = null;
    _state.driverAssignmentService?.stopPolling();
    _state.bookingService?.stopLocationTracking();

    if (_state.mounted) {
      _state.setState(() {
        _state.activeBookingId = null;
        _state.isBookingConfirmed = false;
        _state.isDriverAssigned = false;
      });
    }

    if (completedBookingId != null) {
      await LocalDatabaseService().deleteBookingDetails(completedBookingId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeBookingId');
    await prefs.remove('pickup');
    await prefs.remove('dropoff');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (safeContext.mounted) {
        Navigator.of(safeContext).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CompletedRideScreen(
                arrivedTime: DateTime.now(), bookingId: completedBookingId!),
          ),
        );
      }
    });
  }
}
