import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/main.dart';
// import 'package:pasada_passenger_app/screens/paymentMethodScreen.dart';
import 'package:pasada_passenger_app/screens/routeSelection.dart';
// import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:pasada_passenger_app/services/driverAssignmentService.dart';
import 'package:pasada_passenger_app/services/driverService.dart';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:pasada_passenger_app/widgets/booking_status_manager.dart';
// import 'package:pasada_passenger_app/widgets/booking_details_container.dart';
// import 'package:pasada_passenger_app/widgets/booking_status_container.dart';
// import 'package:pasada_passenger_app/widgets/booking_status_manager.dart';
import 'package:pasada_passenger_app/widgets/loading_dialog.dart';
import 'package:pasada_passenger_app/widgets/onboarding_dialog.dart';
// import 'package:pasada_passenger_app/widgets/payment_details_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import '../location/locationSearchScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
// import 'package:pasada_passenger_app/models/stop.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:pasada_passenger_app/services/localDatabaseService.dart';
import 'package:pasada_passenger_app/widgets/location_input_container.dart';
import 'package:pasada_passenger_app/widgets/home_screen_fab.dart';

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
  final GlobalKey locationInputContainerKey = GlobalKey();
  final GlobalKey bookingStatusContainerKey = GlobalKey();
  double locationInputContainerHeight = 0.0;
  double bookingStatusContainerHeight = 0.0;

  final GlobalKey<MapScreenState> mapScreenKey =
      GlobalKey<MapScreenState>(); // global key para maaccess si MapScreenState
  SelectedLocation?
      selectedPickUpLocation; // variable for the selected pick up location
  SelectedLocation?
      selectedDropOffLocation; // variable for the selected drop off location
  String etaText = '--'; // eta text variable placeholder yung "--"
  bool isSearchingPickup = true; // true = pick-up, false - drop-off
  DateTime? lastBackPressTime;
  // keep state alive
  @override
  bool get wantKeepAlive => true;
  bool isBookingConfirmed = false;
  bool _isInitialized = false;

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

  // Add a state variable to track booking status
  String bookingStatus = 'requested';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => measureContainers());
  }

  // Method to restore any active booking from local database on app start
  Future<void> loadActiveBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = prefs.getInt('activeBookingId');
    if (bookingId == null) return;

    // First try to get booking from API
    _bookingService = BookingService();
    final apiBooking = await _bookingService!.getBookingDetails(bookingId);

    if (apiBooking != null) {
      // Use API data
      final status = apiBooking['ride_status'];
      if (status == 'searching' ||
          status == 'assigned' ||
          status == 'ongoing' ||
          status == 'requested') {
        setState(() {
          isBookingConfirmed = true;
          bookingStatus = status;
          selectedPickUpLocation = SelectedLocation(
            apiBooking['pickup_address'],
            LatLng(
              double.parse(apiBooking['pickup_lat'].toString()),
              double.parse(apiBooking['pickup_lng'].toString()),
            ),
          );
          selectedDropOffLocation = SelectedLocation(
            apiBooking['dropoff_address'],
            LatLng(
              double.parse(apiBooking['dropoff_lat'].toString()),
              double.parse(apiBooking['dropoff_lng'].toString()),
            ),
          );
          currentFare = double.parse(apiBooking['fare'].toString());
          selectedPaymentMethod = apiBooking['payment_method'] ?? 'Cash';
        });

        // If driver is assigned, fetch driver details
        if (apiBooking['driver_id'] != null) {
          _fetchDriverDetails(apiBooking['driver_id'].toString());
        }

        // Animate into the booking status view
        _bookingAnimationController.forward();

        // Resume polling for status updates
        _driverAssignmentService = DriverAssignmentService();
        _driverAssignmentService!.pollForDriverAssignment(
          bookingId,
          (driverData) => _updateDriverDetails(driverData),
          onError: () {/* optionally handle polling errors */},
          onStatusChange: (status) {
            setState(() => bookingStatus = status);
            _fetchAndUpdateBookingDetails(bookingId);
          },
        );
        WidgetsBinding.instance
            .addPostFrameCallback((_) => measureContainers());
        return;
      }
    }

    // Fallback to local database if API fails
    final localBooking =
        await LocalDatabaseService().getBookingDetails(bookingId);
    if (localBooking == null) {
      await prefs.remove('activeBookingId');
      return;
    }

    // Rest of your existing code for local database fallback...
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
    WidgetsBinding.instance.addPostFrameCallback((_) => measureContainers());
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
          measureContainers();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shouldReinitialize = PageStorage.of(context).readState(
            context,
            identifier: const ValueKey('homeInitialized'),
          ) ==
          false;

      if (!_isInitialized || shouldReinitialize) {
        LoadingDialog.show(context, message: 'Initializing resources...');
        try {
          await InitializationService.initialize(context);
          _isInitialized = true;
          PageStorage.of(context).writeState(
            context,
            true,
            identifier: const ValueKey('homeInitialized'),
          );
        } catch (e) {
          debugPrint('Initialization error: $e');
        } finally {
          if (mounted) {
            LoadingDialog.hide(context);
          }
        }
      }

      if (_hasOnboardingBeenCalled) return;
      _hasOnboardingBeenCalled = true;

      await loadActiveBooking();
      if (isBookingConfirmed) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => measureContainers());
        return;
      }

      loadLocation();
      loadPaymentMethod();
      measureContainers();

      await showOnboardingDialog(context);
      NotificationService.showAvailabilityNotification();
    });
  }

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
    if (selectedRoute != null &&
        selectedPickUpLocation != null &&
        selectedDropOffLocation != null) {
      final int routeId = selectedRoute!['officialroute_id'] ?? 0;
      final stopsService = StopsService();
      final pickupStop = await stopsService.findClosestStop(
          selectedPickUpLocation!.coordinates, routeId);
      final dropoffStop = await stopsService.findClosestStop(
          selectedDropOffLocation!.coordinates, routeId);
      if (pickupStop != null && dropoffStop != null) {
        if (dropoffStop.order <= pickupStop.order) {
          Fluttertoast.showToast(
              msg: 'Invalid route: drop-off must be after pick-up.');
          return;
        }
      }
    }

    final user = supabase.auth.currentUser;
    if (user != null && selectedRoute != null) {
      setState(() {
        isBookingConfirmed = true;
        bookingStatus = 'requested';
      });
      _bookingAnimationController.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) => measureContainers());

      _bookingService = BookingService();
      final bookingService = _bookingService!;
      int routeId = selectedRoute!['officialroute_id'] ?? 0;
      final bookingResult = await bookingService.createBooking(
        passengerId: user.id,
        routeId: routeId,
        pickupAddress: selectedPickUpLocation?.address ?? 'Unknown',
        pickupCoordinates:
            selectedPickUpLocation?.coordinates ?? const LatLng(0, 0),
        dropoffAddress: selectedDropOffLocation?.address ?? 'Unknown',
        dropoffCoordinates:
            selectedDropOffLocation?.coordinates ?? const LatLng(0, 0),
        paymentMethod: selectedPaymentMethod ?? 'Cash',
        fare: currentFare,
        seatingPreference: _seatingPreference.value,
        onDriverAssigned: (details) =>
            _loadBookingAfterDriverAssignment(details.bookingId),
        onStatusChange: (status) {
          setState(() {
            bookingStatus = status;
            if (status == 'cancelled') _handleBookingCancellation();
          });
        },
        onTimeout: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => ResponsiveDialog(
              title: 'No Drivers Available',
              content:
                  const Text('Booking cancelled due to no available drivers.'),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'))
              ],
            ),
          ).then((_) => _handleBookingCancellation());
        },
      );

      if (bookingResult.success) {
        final details = bookingResult.booking!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('activeBookingId', details.bookingId);
        _activeBookingId = details.bookingId;
        setState(() => bookingStatus = details.rideStatus);
        bookingService.startLocationTracking(user.id);
        setState(() => isDriverAssigned = false);
        _driverAssignmentService = DriverAssignmentService();
      } else {
        Fluttertoast.showToast(
            msg: bookingResult.errorMessage ?? 'Booking failed');
        _handleBookingCancellation();
      }
    } else {
      Fluttertoast.showToast(msg: 'User or route missing.');
      _handleBookingCancellation();
    }
  }

  void _handleBookingCancellation() {
    _driverAssignmentService?.stopPolling();
    _bookingService?.stopLocationTracking();
    SharedPreferences.getInstance().then((prefs) async {
      if (_activeBookingId != null) {
        await LocalDatabaseService().deleteBookingDetails(_activeBookingId!);
      }
      await prefs.remove('activeBookingId');
      await prefs.remove('pickup');
      await prefs.remove('dropoff');
    });
    mapScreenKey.currentState?.clearAll();
    setState(() {
      isBookingConfirmed = false;
      isDriverAssigned = false;
      _activeBookingId = null;
      selectedPickUpLocation = null;
      selectedDropOffLocation = null;
      selectedRoute = null; // Also clear the route selection
    });
    _bookingAnimationController.reverse();
    WidgetsBinding.instance.addPostFrameCallback((_) => measureContainers());
  }

  void measureContainers() {
    final RenderBox? locationBox = locationInputContainerKey.currentContext
        ?.findRenderObject() as RenderBox?;
    final RenderBox? bookingStatusBox = bookingStatusContainerKey.currentContext
        ?.findRenderObject() as RenderBox?;

    if (mounted) {
      setState(() {
        if (locationBox != null) {
          locationInputContainerHeight = locationBox.size.height;
        }
        if (bookingStatusBox != null) {
          bookingStatusContainerHeight = bookingStatusBox.size.height;
        }
      });
    }
  }

  Future<void> _showSeatingPreferenceDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Seating Preferences',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pili ka, nakaupo ba o nakatayo?',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                _seatingPreference.value = 'sitting';
                Navigator.pop(context);
              },
              child: const Text('Sitting')),
          ElevatedButton(
              onPressed: () {
                _seatingPreference.value = 'standing';
                Navigator.pop(context);
              },
              child: const Text('Standing')),
        ],
      ),
    );
  }

  Future<void> _navigateToLocationSearch(bool isPickup) async {
    int? routeId;
    List<LatLng>? routePolyline;

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
            selectedRoute?['officialroute_id'] = routeId;
          }
        } else if (selectedRoute?['officialroute_id'] != null) {
          routeId = selectedRoute?['officialroute_id'];
        }
        if (selectedRoute?['polyline_coordinates'] != null) {
          routePolyline = selectedRoute?['polyline_coordinates'];
        }
      } catch (e) {
        debugPrint('Error retrieving route ID: $e');
      }
    }

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
          routeDetails: selectedRoute,
          routePolyline: routePolyline,
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
      WidgetsBinding.instance.addPostFrameCallback((_) => measureContainers());
    }
  }

  void saveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (selectedPickUpLocation != null) {
      prefs.setString('pickup', jsonEncode(selectedPickUpLocation!.toJson()));
    }
    if (selectedDropOffLocation != null) {
      prefs.setString('dropoff', jsonEncode(selectedDropOffLocation!.toJson()));
    }
  }

  void loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final pickupJson = prefs.getString('pickup');
      if (pickupJson != null) {
        selectedPickUpLocation =
            SelectedLocation.fromJson(jsonDecode(pickupJson));
      }
      final dropoffJson = prefs.getString('dropoff');
      if (dropoffJson != null) {
        selectedDropOffLocation =
            SelectedLocation.fromJson(jsonDecode(dropoffJson));
      }
    });
    if (selectedPickUpLocation != null && selectedDropOffLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapScreenKey.currentState?.updateLocations(
          pickup: selectedPickUpLocation!.coordinates,
          dropoff: selectedDropOffLocation!.coordinates,
        );
      });
    }
  }

  double calculateBottomPadding() {
    double currentMainContainerHeight = 0.0;
    // Determine the height of the primary container at the bottom
    if (isBookingConfirmed) {
      currentMainContainerHeight = bookingStatusContainerHeight;
    } else {
      currentMainContainerHeight = locationInputContainerHeight;
      if (isNotificationVisible && locationInputContainerHeight == 0) {
        currentMainContainerHeight += notificationHeight + 10;
      }
    }
    return currentMainContainerHeight + 20.0; // Base padding for FAB/Map logo
  }

  double calculateMapPadding() {
    double totalOffset = 0.0;
    if (isBookingConfirmed) {
      totalOffset = bookingStatusContainerHeight;
    } else {
      totalOffset = locationInputContainerHeight;
      // Only add notification height if the location input container itself hasn't accounted for it
      // (i.e., if locationInputContainerHeight is 0, meaning it's not the measured bottom element yet)
      if (isNotificationVisible && locationInputContainerHeight == 0) {
        totalOffset += notificationHeight + 10; // 10 for SizedBox
      }
    }
    return totalOffset + 20.0; // Base padding
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => measureContainers());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final now = DateTime.now();
          final difference = lastBackPressTime != null
              ? now.difference(lastBackPressTime!)
              : const Duration(seconds: 3);
          if (difference > const Duration(seconds: 2)) {
            lastBackPressTime = now;
            Fluttertoast.showToast(msg: "Press back again to exit.");
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
            final fabIconSize = screenWidth * 0.06;
            final bottomNavBarHeight = 20.0;
            final fabVerticalSpacing = 10.0;

            return Stack(
              children: [
                MapScreen(
                  key: mapScreenKey,
                  pickUpLocation: selectedPickUpLocation?.coordinates,
                  dropOffLocation: selectedDropOffLocation?.coordinates,
                  bottomPadding:
                      calculateMapPadding() / // Use new method for map
                          MediaQuery.of(context).size.height,
                  onEtaUpdated: (eta) {
                    if (mounted) setState(() => etaText = eta);
                  },
                  onFareUpdated: (fare) {
                    if (mounted) setState(() => currentFare = fare);
                  },
                  selectedRoute: selectedRoute,
                  routePolyline:
                      selectedRoute?['polyline_coordinates'] as List<LatLng>?,
                ),
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
                HomeScreenFAB(
                  mapScreenKey:
                      mapScreenKey as GlobalKey<State<StatefulWidget>>,
                  downwardAnimation: _downwardAnimation,
                  bookingAnimationControllerValue:
                      _bookingAnimationController, // Pass the controller directly
                  responsivePadding: responsivePadding,
                  fabVerticalSpacing: fabVerticalSpacing,
                  iconSize: fabIconSize,
                  onPressed: () async {
                    final mapState = mapScreenKey.currentState;
                    if (mapState != null) {
                      if (!mapState.isLocationInitialized) {
                        await mapState.initializeLocation();
                      }
                      if (mapState.currentLocation != null) {
                        mapState.animateToLocation(mapState.currentLocation!);
                      }
                      mapState.pulseCurrentLocationMarker();
                    }
                  },
                  bottomOffset:
                      calculateBottomPadding(), // FAB uses the main calculation
                ),
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
                              key: locationInputContainerKey, // Assign key here
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNotificationVisible)
                                  _buildNotificationContainer(),
                                SizedBox(height: 10),
                                LocationInputContainer(
                                    parentContext: context,
                                    screenWidth: screenWidth,
                                    responsivePadding: responsivePadding,
                                    iconSize:
                                        fabIconSize, // Use fabIconSize from LayoutBuilder
                                    isRouteSelected: isRouteSelected,
                                    selectedPickUpLocation:
                                        selectedPickUpLocation,
                                    selectedDropOffLocation:
                                        selectedDropOffLocation,
                                    etaText: etaText,
                                    currentFare: currentFare,
                                    selectedPaymentMethod:
                                        selectedPaymentMethod,
                                    seatingPreference: _seatingPreference,
                                    onNavigateToLocationSearch:
                                        _navigateToLocationSearch,
                                    onShowSeatingPreferenceDialog:
                                        _showSeatingPreferenceDialog,
                                    onConfirmBooking:
                                        _handleBookingConfirmation,
                                    onPaymentMethodSelected: (method) {
                                      setState(
                                          () => selectedPaymentMethod = method);
                                      SharedPreferences.getInstance().then(
                                          (prefs) => prefs.setString(
                                              'selectedPaymentMethod', method));
                                    }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (isBookingConfirmed)
                  Positioned(
                    bottom: bottomNavBarHeight,
                    left: responsivePadding,
                    right: responsivePadding,
                    child: AnimatedBuilder(
                      animation: _bookingAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -_upwardAnimation.value),
                          child: Opacity(
                            opacity: _bookingAnimationController.value,
                            child: Container(
                              // Wrap BookingStatusManager with a container and key
                              key: bookingStatusContainerKey,
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
                                bookingStatus: bookingStatus,
                              ),
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
                blurRadius: MediaQuery.of(context).size.width * 0.03)
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
                    color: isDarkMode ? Colors.white : Colors.black54),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: isDarkMode ? Colors.white : Colors.black)
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
                  measureContainers();
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
                      blurRadius: MediaQuery.of(context).size.width * 0.03)
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: const Color(0xFF00CC58), size: 24),
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
                            icon: Icon(Icons.close,
                                color: const Color(0xFF00CC58)),
                            onPressed: () {
                              setState(() {
                                isNotificationVisible = false;
                                measureContainers();
                              });
                            })),
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
    var driver = driverData['driver'];
    if (driver == null) return;
    if (driver is List && driver.isNotEmpty) driver = driver[0];
    setState(() {
      driverName = _extractField(driver, ['full_name', 'name', 'driver_name']);
      plateNumber = _extractField(
          driver, ['plate_number', 'plateNumber', 'vehicle_plate', 'plate']);
      phoneNumber = _extractField(driver, [
        'driver_number',
        'phone_number',
        'phoneNumber',
        'contact_number',
        'phone'
      ]);
      isDriverAssigned = true;
      bookingStatus = 'accepted';
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
    _bookingService ??= BookingService();
    final details = await _bookingService!.getBookingDetails(bookingId);
    if (details != null && mounted) {
      setState(() {
        bookingStatus = details['ride_status'] ?? 'requested';
        if (details['fare'] != null) {
          currentFare =
              double.tryParse(details['fare'].toString()) ?? currentFare;
        }
        if (details['payment_method'] != null) {
          selectedPaymentMethod = details['payment_method'];
        }
      });
      if (details['driver_id'] != null) {
        _fetchDriverDetails(details['driver_id'].toString());
      }
    }
  }

  Future<void> _fetchDriverDetails(String driverId) async {
    final service = DriverService();
    final details = await service.getDriverDetails(driverId);
    if (details != null && mounted) _updateDriverDetails({'driver': details});
  }

  void _loadBookingAfterDriverAssignment(int bookingId) {
    _driverAssignmentService
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
      setState(() {
        driverName = driver['full_name'] ?? 'Driver';
        phoneNumber = driver['driver_number'] ?? '';
        plateNumber = plate;
        isDriverAssigned = true;
        bookingStatus = 'accepted';
      });
    } catch (e) {
      debugPrint('DB Query Error: $e');
    }
  }
}
