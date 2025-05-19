import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:pasada_passenger_app/screens/paymentMethodScreen.dart';
import 'package:pasada_passenger_app/screens/routeSelection.dart';
// import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:pasada_passenger_app/services/driverAssignmentService.dart';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:pasada_passenger_app/widgets/booking_status_manager.dart';
// import 'package:pasada_passenger_app/widgets/booking_details_container.dart';
// import 'package:pasada_passenger_app/widgets/booking_status_container.dart';
// import 'package:pasada_passenger_app/widgets/booking_status_manager.dart';
import 'package:pasada_passenger_app/widgets/onboarding_dialog.dart';
// import 'package:pasada_passenger_app/widgets/payment_details_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import '../location/locationSearchScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
// import 'package:pasada_passenger_app/models/stop.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:pasada_passenger_app/services/localDatabaseService.dart';

// stateless tong widget na to so meaning yung mga properties niya ay di na mababago

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreenStateful();
  }
}

// stateful na makakapagrebuild dynamically kapag nagbago yung data
class HomeScreenStateful extends StatefulWidget {
  const HomeScreenStateful({super.key});

  @override
  // creates the mutable state para sa widget
  State<HomeScreenStateful> createState() => HomeScreenPageState();
}

class HomeScreenPageState extends State<HomeScreenStateful>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin {
  // Booking and polling services for cancellation
  BookingService? _bookingService;
  DriverAssignmentService? _driverAssignmentService;
  int? _activeBookingId;
  final GlobalKey containerKey =
      GlobalKey(); // container key for the location container
  double containerHeight = 0.0; // container height idk might reimplement this
  final GlobalKey<MapScreenState> mapScreenKey =
      GlobalKey<MapScreenState>(); // global key para maaccess si MapScreenState
  SelectedLocation?
      selectedPickUpLocation; // variable for the selected pick up location
  SelectedLocation?
      selectedDropOffLocation; // variable for the selected drop off location
  String etaText = '--'; // eta text variable placeholder yung "--"
  bool isSearchingPickup = true; // true = pick-up, false - drop-off
  DateTime? lastBackPressTime;
  // keep state alive my nigger
  @override
  bool get wantKeepAlive => true;
  bool isBookingConfirmed = false;

  // state variable for the payment method
  String? selectedPaymentMethod;
  final double iconSize = 24;

  Map<String, dynamic>? selectedRoute;
  bool isNotificationVisible = true;
  double notificationDragOffset = 0;
  final double notificationHeight = 60.0;

  double currentFare = 0.0;

  late AnimationController _bookingAnimationController;
  late Animation<double> _downwardAnimation;
  late Animation<double> _upwardAnimation;

  final ValueNotifier<String> _seatingPreference =
      ValueNotifier<String>('Sitting');

  bool get isRouteSelected =>
      selectedRoute != null && selectedRoute!['route_name'] != 'Select Route';

  // Add a state variable to track if a driver is assigned
  bool isDriverAssigned = false;
  // Add a flag to ensure onboarding is requested only once
  bool _hasOnboardingBeenCalled = false;

  String driverName = '';
  String plateNumber = '';
  String vehicleModel = '';
  String phoneNumber = '';

  Future<void> _showRouteSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteSelection(),
      ),
    );
    if (result != null && mounted) {
      setState(() => selectedRoute = result);

      debugPrint('Selected route: ${result!['route_name']}');
      debugPrint('Route details: $result');

      // Make sure we have the route ID
      if (result['officialroute_id'] == null) {
        try {
          final routeResponse = await Supabase.instance.client
              .from('official_routes')
              .select('officialroute_id')
              .eq('route_name', result['route_name'])
              .single();

          setState(() {
            selectedRoute!['officialroute_id'] =
                routeResponse['officialroute_id'];
          });
          debugPrint(
              'Retrieved route ID: ${selectedRoute!['officialroute_id']}');
        } catch (e) {
          debugPrint('Error retrieving route ID: $e');
        }
      }

      // Get origin and destination coordinates
      LatLng? originCoordinates = result['origin_coordinates'];
      LatLng? destinationCoordinates = result['destination_coordinates'];
      String? destinationName = result['destination_name']?.toString();

      if (result['intermediate_coordinates'] != null) {
        debugPrint(
            'Route has intermediate coordinates: ${result['intermediate_coordinates']}');

        // Use the new method for route polylines with origin and destination
        mapScreenKey.currentState?.generateRoutePolyline(
          result['intermediate_coordinates'],
          originCoordinates: originCoordinates,
          destinationCoordinates: destinationCoordinates,
          destinationName: destinationName,
        );
      } else {
        debugPrint('Route does not have intermediate coordinates');

        // Fallback to the original method if no intermediate coordinates
        if (originCoordinates != null && destinationCoordinates != null) {
          mapScreenKey.currentState?.generatePolylineBetween(
            originCoordinates,
            destinationCoordinates,
          );
        }
      }
    }
  }

  // method para sa pagsplit ng location names from landmark to address
  List<String> splitLocation(String location) {
    final List<String> parts = location.split(','); // split by comma
    if (parts.length < 2) {
      return [location, '']; // kapag exact address si location then leave as is
    }
    return [
      parts[0],
      parts.sublist(1).join(', ')
    ]; // sa unahan o ibabaw yung landmark which is yung parts[0] the rest is sa baba which is yung parts.sublist(1). tapos join(',')  na lang
  }

  /// Update yung proper location base duon sa search type
  void updateLocation(SelectedLocation location, bool isPickup) {
    setState(() {
      if (isPickup) {
        selectedPickUpLocation = location;
      } else {
        selectedDropOffLocation = location;
      }
    });
    saveLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => measureContainer());
  }

  // Method to restore any active booking from local database on app start
  Future<void> loadActiveBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = prefs.getInt('activeBookingId');
    if (bookingId == null) return;
    final localBooking =
        await LocalDatabaseService().getBookingDetails(bookingId);
    if (localBooking == null) {
      await prefs.remove('activeBookingId');
      return;
    }
    final status = localBooking.rideStatus;
    if (status == 'searching' || status == 'assigned' || status == 'ongoing') {
      setState(() {
        isBookingConfirmed = true;
        selectedPickUpLocation = SelectedLocation(
          localBooking.pickupAddress,
          localBooking.pickupCoordinates,
        );
        selectedDropOffLocation = SelectedLocation(
          localBooking.dropoffAddress,
          localBooking.dropoffCoordinates,
        );
        currentFare = localBooking.fare;
      });
      // Animate into the booking status view
      _bookingAnimationController.forward();
      // Restore payment method if any
      final savedMethod = prefs.getString('selectedPaymentMethod');
      if (savedMethod != null && mounted) {
        setState(() => selectedPaymentMethod = savedMethod);
      }
      // Restore selected route details
      try {
        final routeResponse = await Supabase.instance.client
            .from('official_routes')
            .select(
                'route_name, origin_lat, origin_lng, destination_lat, destination_lng, intermediate_coordinates, destination_name, polyline_coordinates')
            .eq('officialroute_id', localBooking.routeId)
            .single();
        final Map<String, dynamic> routeMap =
            Map<String, dynamic>.from(routeResponse as Map);
        // Parse intermediate_coordinates
        var inter = routeMap['intermediate_coordinates'];
        if (inter is String) {
          try {
            inter = jsonDecode(inter);
          } catch (_) {}
        }
        routeMap['intermediate_coordinates'] = inter;
        // Parse origin/destination coords
        routeMap['origin_coordinates'] = LatLng(
          double.parse(routeMap['origin_lat'].toString()),
          double.parse(routeMap['origin_lng'].toString()),
        );
        routeMap['destination_coordinates'] = LatLng(
          double.parse(routeMap['destination_lat'].toString()),
          double.parse(routeMap['destination_lng'].toString()),
        );
        setState(() {
          selectedRoute = routeMap;
        });
      } catch (e) {
        debugPrint('Error restoring route: $e');
      }
      // Initialize map and generate route polyline
      mapScreenKey.currentState?.initializeLocation();
      if (selectedRoute != null) {
        mapScreenKey.currentState?.generateRoutePolyline(
          selectedRoute!['intermediate_coordinates'] as List<dynamic>,
          originCoordinates: selectedRoute!['origin_coordinates'] as LatLng?,
          destinationCoordinates:
              selectedRoute!['destination_coordinates'] as LatLng?,
          destinationName: selectedRoute!['destination_name']?.toString(),
        );
      }
      // Resume location tracking and driver polling
      final user = supabase.auth.currentUser;
      if (user != null) {
        // initialize and store services so they can be cancelled
        _bookingService = BookingService();
        _bookingService!.startLocationTracking(user.id);
        _driverAssignmentService = DriverAssignmentService();
        _driverAssignmentService!.pollForDriverAssignment(
          bookingId,
          (driverData) => _updateDriverDetails(driverData),
          onError: () {/* optionally handle polling errors */},
        );
      }
    } else {
      // Completed or cancelled booking, clear saved id
      await prefs.remove('activeBookingId');
    }
  }

  @override
  void initState() {
    super.initState();

    _bookingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _downwardAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(CurvedAnimation(
      parent: _bookingAnimationController,
      curve: Curves.easeOut,
    ));

    _upwardAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _bookingAnimationController,
      curve: Curves.easeOut,
    ));

    _bookingAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isNotificationVisible = false;
          // Don't reset the controller here
          measureContainer();
        });
      }
    });

    // Replace the existing post-frame callback with a guarded version
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_hasOnboardingBeenCalled) return;
      _hasOnboardingBeenCalled = true;

      // Attempt to restore any active booking
      await loadActiveBooking();
      if (isBookingConfirmed) {
        return;
      }

      loadLocation();
      loadPaymentMethod(); // Add this line to load the payment method
      measureContainer();

      // Show onboarding dialog for new users
      await showOnboardingDialog(context);

      // Use the updated notification service
      NotificationService.showAvailabilityNotification();
    });
  }

  // Add this method to load the saved payment method
  void loadPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMethod = prefs.getString('selectedPaymentMethod');
    if (savedMethod != null && mounted) {
      setState(() {
        selectedPaymentMethod = savedMethod;
      });
    }
  }

  @override
  void dispose() {
    _bookingAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadLocation();
      mapScreenKey.currentState?.initializeLocation();
    }
  }

  Future<void> _handleBookingConfirmation() async {
    // Prevent reverse booking: ensure drop-off stop order > pick-up stop order
    if (selectedRoute != null &&
        selectedPickUpLocation != null &&
        selectedDropOffLocation != null) {
      final int routeId = selectedRoute!['officialroute_id'] ?? 0;
      final stopsService = StopsService();

      // Find closest stops to our selected locations
      final pickupStop = await stopsService.findClosestStop(
          selectedPickUpLocation!.coordinates, routeId);

      final dropoffStop = await stopsService.findClosestStop(
          selectedDropOffLocation!.coordinates, routeId);

      debugPrint(
          'Pickup stop: ${pickupStop?.name}, order: ${pickupStop?.order}');
      debugPrint(
          'Dropoff stop: ${dropoffStop?.name}, order: ${dropoffStop?.order}');

      if (pickupStop != null && dropoffStop != null) {
        if (dropoffStop.order <= pickupStop.order) {
          Fluttertoast.showToast(
            msg:
                'Invalid route: drop-off must be after pick-up for this route.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          return;
        }
      }
    }

    setState(() {
      isBookingConfirmed = true;
    });

    _bookingAnimationController.forward();

    // Get the current user
    final user = supabase.auth.currentUser;
    if (user != null && selectedRoute != null) {
      // Create booking in Supabase and locally
      // initialize booking service for tracking
      _bookingService = BookingService();
      final bookingService = _bookingService!;

      // Make sure we have the route ID
      int routeId = selectedRoute!['officialroute_id'] ?? 0;

      // Create the booking
      final bookingId = await bookingService.createBooking(
        passengerId: user.id,
        routeId: routeId,
        pickupAddress: selectedPickUpLocation?.address ?? 'Unknown location',
        pickupCoordinates:
            selectedPickUpLocation?.coordinates ?? const LatLng(0, 0),
        dropoffAddress: selectedDropOffLocation?.address ?? 'Unknown location',
        dropoffCoordinates:
            selectedDropOffLocation?.coordinates ?? const LatLng(0, 0),
        paymentMethod: selectedPaymentMethod ?? 'Cash',
        fare: currentFare,
        seatingPreference: _seatingPreference.value,
      );

      if (bookingId != null) {
        debugPrint('Booking created with ID: $bookingId');

        // Persist active booking for restore on app restart
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('activeBookingId', bookingId);
        _activeBookingId = bookingId;

        // Start location tracking for the passenger
        bookingService.startLocationTracking(user.id);

        try {
          final success = await bookingService.assignDriver(
            bookingId,
            fare: currentFare,
            paymentMethod: selectedPaymentMethod ?? 'Cash',
          );
          if (success) {
            // Set driver assignment status to false initially
            setState(() {
              isDriverAssigned = false;
            });

            // initialize polling service for driver assignment
            _driverAssignmentService = DriverAssignmentService();
            _driverAssignmentService!.pollForDriverAssignment(bookingId,
                (driverData) {
              // Update driver details and set isDriverAssigned to true
              _updateDriverDetails(driverData);
            }, onError: () {
              // Handle polling errors
              setState(() {
                isDriverAssigned = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Failed to connect to driver service. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );

              // Cancel the booking
              _handleBookingCancellation();
            });
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to request a driver. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Unable to create booking. Please try again.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: const Color(0xFF1E1E1E),
              textColor: const Color(0xFFF5F5F5),
            );

            // Revert the booking confirmation UI
            _handleBookingCancellation();
          }
        }
      }
    } else {
      // Handle case where user is not logged in or route is not selected
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Unable to create booking. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF1E1E1E),
          textColor: const Color(0xFFF5F5F5),
        );
        // Revert the booking confirmation UI
        _handleBookingCancellation();
      }
    }
  }

  void _handleBookingCancellation() {
    // Stop background services
    if (_driverAssignmentService != null) {
      _driverAssignmentService!.stopPolling();
    }
    if (_bookingService != null) {
      _bookingService!.stopLocationTracking();
    }
    // Clear saved active booking
    SharedPreferences.getInstance().then((prefs) async {
      if (_activeBookingId != null) {
        await LocalDatabaseService().deleteBookingDetails(_activeBookingId!);
      }
      await prefs.remove('activeBookingId');
      // Clear persisted pick-up and drop-off locations
      await prefs.remove('pickup');
      await prefs.remove('dropoff');
    });
    // Clear map UI and state
    mapScreenKey.currentState?.clearAll();
    setState(() {
      isBookingConfirmed = false;
      isDriverAssigned = false;
      _activeBookingId = null;
      selectedPickUpLocation = null;
      selectedDropOffLocation = null;
      selectedRoute = null;
    });
    _bookingAnimationController.reverse();
  }

  void measureContainer() {
    final RenderBox? box =
        containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && mounted) {
      setState(() {
        containerHeight = box.size.height;
      });
    }
  }

  Future<void> _showSeatingPreferenceDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // final screenSize = MediaQuery.of(context).size;

    await showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Seating Preferences',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pili ka, nakaupo ba o nakatayo?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: isDarkMode
                    ? const Color(0xFFDEDEDE)
                    : const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () {
              _seatingPreference.value = 'sitting';
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(150, 40),
              backgroundColor: const Color(0xFF00CC58),
              foregroundColor: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Sitting',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _seatingPreference.value = 'standing';
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: const Color(0xFF00CC58),
                  width: 3,
                ),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(150, 40),
              backgroundColor: Colors.transparent,
              foregroundColor: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Standing',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToLocationSearch(bool isPickup) async {
    int? routeId;
    List<LatLng>? routePolyline;

    // If selectedRoute doesn't have officialroute_id, query it from the database
    if (selectedRoute != null) {
      try {
        final routeName = selectedRoute?['route_name'];
        if (routeName != null && selectedRoute?['officialroute_id'] == null) {
          final response = await Supabase.instance.client
              .from('official_routes')
              .select('officialroute_id')
              .eq('route_name', routeName)
              .single();

          if (response.isNotEmpty) {
            routeId = response['officialroute_id'];
            // Update the selectedRoute with the ID for future use
            selectedRoute?['officialroute_id'] = routeId;
          }
        } else if (selectedRoute?['officialroute_id'] != null) {
          routeId = selectedRoute?['officialroute_id'];
        }

        // Get the polyline coordinates if available
        if (selectedRoute?['polyline_coordinates'] != null) {
          routePolyline = selectedRoute?['polyline_coordinates'];
        }
      } catch (e) {
        debugPrint('Error retrieving route ID: $e');
      }
    }

    debugPrint('Navigating to search with routeID: $routeId');

    // Determine pick-up stop order for drop-off validation
    int? pickupOrder;
    if (!isPickup && selectedPickUpLocation != null && routeId != null) {
      final stopsService = StopsService();
      final pickupStop = await stopsService.findClosestStop(
          selectedPickUpLocation!.coordinates, routeId);
      pickupOrder = pickupStop?.order;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchLocationScreen(
          isPickup: isPickup,
          routeID: routeId,
          routeDetails: selectedRoute, // Pass the entire route details
          routePolyline: routePolyline, // Pass the polyline coordinates
          pickupOrder: pickupOrder,
        ),
      ),
    );

    if (result != null && result is SelectedLocation) {
      setState(() {
        if (isPickup) {
          selectedPickUpLocation = result;
        } else {
          selectedDropOffLocation = result;
        }
      });
    }
  }

  // saving location to avoid getting removed through navigation
  void saveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (selectedPickUpLocation != null) {
      prefs.setString(
        'pickup',
        jsonEncode(SelectedLocation(
          selectedPickUpLocation!.address,
          selectedPickUpLocation!.coordinates,
        ).toJson()),
      );
    }
    if (selectedDropOffLocation != null) {
      prefs.setString(
        'dropoff',
        jsonEncode(SelectedLocation(
          selectedDropOffLocation!.address,
          selectedDropOffLocation!.coordinates,
        ).toJson()),
      );
    }
  }

  // loading location
  void loadLocation() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedPickUpLocation = _loadLocation(prefs, 'pickup');
      selectedDropOffLocation = _loadLocation(prefs, 'dropoff');
    });

    if (selectedPickUpLocation != null && selectedDropOffLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use updateLocations to respect the selected route's polyline
        mapScreenKey.currentState?.updateLocations(
          pickup: selectedPickUpLocation!.coordinates,
          dropoff: selectedDropOffLocation!.coordinates,
        );
      });
    }
  }

  SelectedLocation? _loadLocation(SharedPreferences prefs, String key) {
    final json = prefs.getString(key);
    return json != null ? SelectedLocation.fromJson(jsonDecode(json)) : null;
  }

  // Calculate the bottom padding for FAB and Google logo
  double calculateBottomPadding() {
    double basePadding = containerHeight + 20.0;
    if (isNotificationVisible) {
      // Add notification height and spacing when notification is visible
      basePadding += notificationHeight +
          10; // 10 is the SizedBox height between notification and location container
    }
    return basePadding;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false, // bawal navigation pops
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          final now = DateTime.now();
          final difference = lastBackPressTime != null
              ? now.difference(lastBackPressTime!)
              : Duration(seconds: 3);
          if (difference > Duration(seconds: 2)) {
            lastBackPressTime = now;
            Fluttertoast.showToast(
              msg: "Press back again to exit.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final responsivePadding = screenWidth * 0.05;
            final iconSize = screenWidth * 0.06;
            final bottomNavBarHeight = 20.0;
            final fabVerticalSpacing = 10.0;

            return Stack(
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _seatingPreference,
                  builder: (context, preference, _) => SizedBox(),
                ),
                MapScreen(
                  key: mapScreenKey,
                  pickUpLocation: selectedPickUpLocation?.coordinates,
                  dropOffLocation: selectedDropOffLocation?.coordinates,
                  bottomPadding: calculateBottomPadding() /
                      MediaQuery.of(context).size.height,
                  onEtaUpdated: (eta) {
                    debugPrint('HomeScreen received ETA update: "$eta"');
                    if (mounted) {
                      setState(() => etaText = eta);
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => measureContainer());
                    }
                  },
                  onFareUpdated: (fare) {
                    debugPrint(
                        'HomeScreen received fare update: ₱${fare.toStringAsFixed(2)}');
                    setState(() {
                      currentFare = fare;
                    });
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => measureContainer());
                  },
                  selectedRoute: selectedRoute,
                  routePolyline:
                      selectedRoute?['polyline_coordinates'] as List<LatLng>?,
                ),

                // Route Selection at the top
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: responsivePadding,
                  right: responsivePadding,
                  child: AnimatedBuilder(
                    animation: _bookingAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_downwardAnimation.value),
                        child: Opacity(
                          opacity: 1 - _bookingAnimationController.value,
                          child: _buildRouteSelectionContainer(),
                        ),
                      );
                    },
                  ),
                ),

                // Location FAB
                Positioned(
                  right: responsivePadding,
                  bottom: calculateBottomPadding() + fabVerticalSpacing,
                  child: AnimatedBuilder(
                    animation: _bookingAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _downwardAnimation.value),
                        child: Opacity(
                          opacity: 1 - _bookingAnimationController.value,
                          child: LocationFAB(
                            heroTag: "homeLocationFAB",
                            onPressed: () async {
                              final mapState = mapScreenKey.currentState;
                              if (mapState != null) {
                                if (!mapState.isLocationInitialized) {
                                  await mapState.initializeLocation();
                                }
                                if (mapState.currentLocation != null) {
                                  mapState.animateToLocation(
                                      mapState.currentLocation!);
                                }
                                mapState.pulseCurrentLocationMarker();
                              }
                            },
                            iconSize: iconSize,
                            buttonSize: screenWidth * 0.12,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFFF5F5F5),
                            iconColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF00E865)
                                    : const Color(0xFF00CC58),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main booking container
                if (!isBookingConfirmed)
                  Positioned(
                    bottom: bottomNavBarHeight,
                    left: responsivePadding,
                    right: responsivePadding,
                    child: AnimatedBuilder(
                      animation: _bookingAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _downwardAnimation.value),
                          child: Opacity(
                            opacity: 1 - _bookingAnimationController.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNotificationVisible)
                                  _buildNotificationContainer(),
                                SizedBox(height: 10),
                                Container(
                                  key: containerKey,
                                  child: buildLocationContainer(
                                    context,
                                    screenWidth,
                                    responsivePadding,
                                    iconSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Booking status containers
                if (isBookingConfirmed)
                  Positioned(
                    bottom: bottomNavBarHeight,
                    left: responsivePadding,
                    right: responsivePadding,
                    child: AnimatedBuilder(
                      animation: _bookingAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0,
                              -_upwardAnimation.value), // Use upward animation
                          child: Opacity(
                            opacity: _bookingAnimationController.value,
                            child: BookingStatusManager(
                              pickupLocation: selectedPickUpLocation,
                              dropoffLocation: selectedDropOffLocation,
                              ETA: etaText,
                              paymentMethod: selectedPaymentMethod ?? 'Cash',
                              fare: currentFare,
                              onCancelBooking: _handleBookingCancellation,
                              driverName: driverName,
                              plateNumber: plateNumber,
                              vehicleModel: vehicleModel,
                              phoneNumber: phoneNumber,
                              isDriverAssigned: isDriverAssigned,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildLocationContainer(BuildContext context, double screenWidth,
      double padding, double iconSize) {
    String svgAssetPickup = 'assets/svg/pinpickup.svg';
    String svgAssetDropOff = 'assets/svg/pindropoff.svg';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _bookingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _downwardAnimation.value),
          child: Opacity(
            opacity: 1 - _bookingAnimationController.value,
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: screenWidth * 0.03,
                    spreadRadius: screenWidth * 0.005,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildLocationRow(svgAssetPickup, selectedPickUpLocation, true,
                      screenWidth, iconSize,
                      enabled: isRouteSelected),
                  const Divider(),
                  buildLocationRow(svgAssetDropOff, selectedDropOffLocation,
                      false, screenWidth, iconSize,
                      enabled: isRouteSelected),
                  SizedBox(height: 27),
                  if (isRouteSelected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _showSeatingPreferenceDialog,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_seat,
                                  size: 24, // Match payment method icon size
                                  color: const Color(
                                      0xFF00CC58), // Match payment method icon color
                                ),
                                const SizedBox(
                                    width: 12), // Match payment method spacing
                                Text(
                                  'Preference:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isRouteSelected
                                        ? (isDarkMode
                                            ? const Color(0xFFF5F5F5)
                                            : const Color(0xFF121212))
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ValueListenableBuilder<String>(
                                  valueListenable: _seatingPreference,
                                  builder: (context, preference, _) => Text(
                                    preference,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isRouteSelected
                                          ? (isDarkMode
                                              ? const Color(0xFFF5F5F5)
                                              : const Color(0xFF121212))
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: isRouteSelected
                                      ? (isDarkMode
                                          ? const Color(0xFFF5F5F5)
                                          : const Color(0xFF121212))
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: (isRouteSelected &&
                            selectedPickUpLocation != null &&
                            selectedDropOffLocation != null)
                        ? () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentMethodScreen(
                                  currentSelection: selectedPaymentMethod,
                                  fare: currentFare,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                            if (result != null && mounted) {
                              setState(() => selectedPaymentMethod = result);
                              // Save the payment method selection
                              final prefs =
                                  await SharedPreferences.getInstance();
                              prefs.setString('selectedPaymentMethod', result);
                            }
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 24,
                              color: const Color(0xFF00CC58),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedPaymentMethod ?? 'Select Payment Method',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: (isRouteSelected &&
                                        selectedPickUpLocation != null &&
                                        selectedDropOffLocation != null)
                                    ? (isDarkMode
                                        ? const Color(0xFFF5F5F5)
                                        : const Color(0xFF121212))
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: (isRouteSelected &&
                                  selectedPickUpLocation != null &&
                                  selectedDropOffLocation != null)
                              ? (isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212))
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.05),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (selectedPickUpLocation != null &&
                              selectedDropOffLocation != null &&
                              selectedPaymentMethod != null &&
                              isRouteSelected)
                          ? _handleBookingConfirmation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CC58),
                        disabledBackgroundColor: const Color(0xFFD3D3D3),
                        foregroundColor: const Color(0xFFF5F5F5),
                        disabledForegroundColor: const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildLocationRow(String svgAsset, SelectedLocation? location,
      bool isPickup, double screenWidth, double iconSize,
      {required bool enabled}) {
    double iconSize = isPickup ? 15 : 15;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    List<String> locationParts =
        location != null ? splitLocation(location.address) : ['', ''];

    return InkWell(
      onTap: enabled ? () => _navigateToLocationSearch(isPickup) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPickup) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Fare: ",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: enabled
                        ? (isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212))
                        : Colors.grey,
                  ),
                ),
                Text(
                  "₱${currentFare.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: enabled ? const Color(0xFF00CC58) : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ETA: ",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: enabled
                        ? (isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212))
                        : Colors.grey,
                  ),
                ),
                Text(
                  etaText != '--' ? etaText : 'Calculating...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: enabled
                        ? (isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF515151))
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.08)
          ],
          Row(
            children: [
              SvgPicture.asset(
                svgAsset,
                height: iconSize,
                width: iconSize,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      location != null
                          ? locationParts[0]
                          : (isPickup
                              ? 'Pick-up location'
                              : 'Drop-off location'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? (isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212))
                            : Colors.grey,
                      ),
                    ),
                    if (locationParts[1].isNotEmpty) ...[
                      Text(
                        locationParts[1],
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? (isDarkMode
                                  ? const Color(0xFFAAAAAA)
                                  : const Color(0xFF515151))
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelectionContainer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _showRouteSelection,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: MediaQuery.of(context).size.width * 0.03,
              spreadRadius: MediaQuery.of(context).size.width * 0.005,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.route, color: Color(0xFF00CC58)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                selectedRoute?['route_name'] ?? 'Select Route',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? const Color.fromARGB(255, 212, 212, 212)
                      : const Color.fromARGB(255, 78, 78, 78),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationContainer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _downwardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _downwardAnimation.value * notificationHeight),
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                notificationDragOffset += details.delta.dy;
                if (notificationDragOffset > notificationHeight) {
                  isNotificationVisible = false;
                  notificationDragOffset = 0;
                  measureContainer();
                }
              });
            },
            onVerticalDragEnd: (details) {
              if (notificationDragOffset < notificationHeight / 2) {
                setState(() => notificationDragOffset = 0);
              }
            },
            child: Container(
              height: notificationHeight - notificationDragOffset,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: MediaQuery.of(context).size.width * 0.03,
                    spreadRadius: MediaQuery.of(context).size.width * 0.005,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: const Color(0xFF00CC58),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please select a route before choosing locations',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: const Color(0xFF00CC58),
                        ),
                        onPressed: () {
                          // Instead of forwarding the animation controller, just hide the notification
                          setState(() {
                            isNotificationVisible = false;
                            measureContainer();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateDriverDetails(Map<String, dynamic> driverData) {
    if (!mounted) return;

    final driver = driverData['driver'];
    final vehicle = driver['vehicle'];

    setState(() {
      driverName = driver['name'] ?? 'Driver';
      plateNumber = vehicle?['plate_number'] ?? 'Unknown';
      vehicleModel = vehicle?['model'] ?? 'Vehicle';
      phoneNumber = driver['phone_number'] ?? '';

      // This will trigger the BookingStatusManager to show the driver details
      isDriverAssigned = true;
    });
  }
}
