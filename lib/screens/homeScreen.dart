import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/managers/booking_manager.dart';
import 'package:pasada_passenger_app/providers/weather_provider.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:pasada_passenger_app/services/driverAssignmentService.dart';
import 'package:pasada_passenger_app/services/fare_service.dart';
import 'package:pasada_passenger_app/services/home_screen_init_service.dart';
import 'package:pasada_passenger_app/services/location_weather_service.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';
import 'package:pasada_passenger_app/services/route_service.dart';
import 'package:pasada_passenger_app/utils/home_screen_navigation.dart';
import 'package:pasada_passenger_app/utils/home_screen_utils.dart';
import 'package:pasada_passenger_app/widgets/alert_sequence_dialog.dart';
import 'package:pasada_passenger_app/widgets/booking_confirmation_dialog.dart';
import 'package:pasada_passenger_app/widgets/home_booking_sheet.dart';
import 'package:pasada_passenger_app/widgets/home_bottom_section.dart';
import 'package:pasada_passenger_app/widgets/home_header_section.dart';
import 'package:pasada_passenger_app/widgets/home_screen_fab.dart';
import 'package:pasada_passenger_app/widgets/location_input_container.dart';
import 'package:pasada_passenger_app/widgets/seating_preference_sheet.dart';
import 'package:pasada_passenger_app/widgets/weather_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WeatherProvider>(
      create: (_) => WeatherProvider(),
      child: const HomeScreenStateful(),
    );
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
  BookingService? bookingService; // Made public
  DriverAssignmentService? driverAssignmentService; // Made public
  int? activeBookingId; // Made public
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
  double originalFare = 0.0; // Store original fare before discount
  // Controller and current extent for booking bottom sheet
  final DraggableScrollableController _bookingSheetController =
      DraggableScrollableController();
  double _bookingSheetExtent = 0.4;

  late AnimationController bookingAnimationController; // Made public
  late Animation<double> _downwardAnimation;

  final ValueNotifier<String> seatingPreference = // Made public
      ValueNotifier<String>('Sitting');
  final ValueNotifier<String> selectedDiscountSpecification = // Made public
      ValueNotifier<String>('');
  final ValueNotifier<String?> selectedIdImagePath = // Made public
      ValueNotifier<String?>(null);

  bool get isRouteSelected =>
      selectedRoute != null && selectedRoute!['route_name'] != 'Select Route';

  // Add a state variable to track if a driver is assigned
  bool isDriverAssigned = false;
  // Add a flag to ensure onboarding is requested only once
  bool _hasOnboardingBeenCalled = false;
  bool _isRushHourDialogShown = false;
  // Add a flag to ensure startup alerts are shown only once
  bool _hasShownStartupAlerts = false;

  String driverName = '';
  String plateNumber = '';
  String vehicleModel = '';
  String phoneNumber = '';

  // Add a state variable to track booking status
  String bookingStatus = 'requested';

  // Instantiate BookingManager
  late BookingManager _bookingManager;

  Future<void> _showRouteSelection() async {
    final result = await navigateToRouteSelection(context);

    if (result != null && mounted) {
      setState(() {
        selectedRoute = result;
        // Keep existing locations when switching routes - users can clear them manually if needed
        // selectedPickUpLocation = null;
        // selectedDropOffLocation = null;
      });

      // Save the route for persistence
      await RouteService.saveRoute(result);

      debugPrint('Selected route:  ${result['route_name']}');
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

      // Draw the precomputed route polyline if available
      if (result['polyline_coordinates'] != null &&
          result['polyline_coordinates'] is List<LatLng>) {
        final coords = result['polyline_coordinates'] as List<LatLng>;
        mapScreenKey.currentState?.animateRouteDrawing(
          const PolylineId('route'),
          coords,
          const Color(0xFFFFCE21),
          8,
        );
        mapScreenKey.currentState?.zoomToBounds(coords);
      } else if (originCoordinates != null && destinationCoordinates != null) {
        // Fallback to computing the route directly
        final coords = await PolylineService()
            .generateBetween(originCoordinates, destinationCoordinates);
        mapScreenKey.currentState?.animateRouteDrawing(
          const PolylineId('route'),
          coords,
          const Color(0xFFFFCE21),
          8,
        );
        mapScreenKey.currentState?.zoomToBounds(coords);
      }
    }
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
  // MOVED TO BookingManager: Future<void> loadActiveBooking() async { ... }

  @override
  void initState() {
    super.initState();
    // Observe lifecycle to re-show alerts on resume
    WidgetsBinding.instance.addObserver(this);
    // Listen to bottom sheet size changes to adjust map padding
    _bookingSheetController.addListener(() {
      setState(() {
        _bookingSheetExtent = _bookingSheetController.size;
      });
    });
    _bookingManager = BookingManager(this); // Initialize BookingManager

    bookingAnimationController = AnimationController(
      // Use public field
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _downwardAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(CurvedAnimation(
      parent: bookingAnimationController, // Use public field
      curve: Curves.easeOut,
    ));

    bookingAnimationController.addStatusListener((status) {
      // Use public field
      if (status == AnimationStatus.completed) {
        setState(() {
          isNotificationVisible = false;
          measureContainers();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeScreen();
    });
  }

  /// Initialize core resources including weather, then display dialogs after loading
  Future<void> _initializeHomeScreen() async {
    // Boot and load core resources (including weather) first
    await HomeScreenInitService.runInitialization(
      context: context,
      getIsInitialized: () => _isInitialized,
      setIsInitialized: () => _isInitialized = true,
      getHasOnboardingBeenCalled: () => _hasOnboardingBeenCalled,
      setHasOnboardingBeenCalled: () => _hasOnboardingBeenCalled = true,
      getIsRushHourDialogShown: () => _isRushHourDialogShown,
      setRushHourDialogShown: () => _isRushHourDialogShown = true,
      bookingManager: _bookingManager,
      getIsBookingConfirmed: () => isBookingConfirmed,
      measureContainers: measureContainers,
      loadLocation: loadLocation,
      loadPaymentMethod: loadPaymentMethod,
      loadRoute: loadRoute,
    );

    // Show startup alerts only once (weather should be loaded by now)
    if (!_hasShownStartupAlerts) {
      final List<Widget> alertPages = [];
      final weatherProvider = context.read<WeatherProvider>();

      // Rain condition
      if (weatherProvider.isRaining) {
        alertPages.add(const WeatherAlertDialogContent());
      }

      // Show alerts in one unified dialog
      if (alertPages.isNotEmpty) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertSequenceDialog(pages: alertPages),
        );
      }
      _hasShownStartupAlerts = true;

      // If weather wasn't loaded during initialization, try again after a delay
      if (weatherProvider.weather == null && !weatherProvider.isLoading) {
        _retryWeatherAfterDelay();
      }
    }
  }

  /// Retry weather initialization after a delay (fallback for initialization failures)
  void _retryWeatherAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (mounted) {
        final weatherProvider = context.read<WeatherProvider>();
        if (weatherProvider.weather == null && !weatherProvider.isLoading) {
          debugPrint('Retrying weather initialization after delay');
          try {
            final success =
                await LocationWeatherService.fetchAndSubscribe(weatherProvider);
            if (success) {
              debugPrint('Delayed weather initialization successful');
            } else {
              debugPrint('Delayed weather initialization failed');
            }
          } catch (e) {
            debugPrint('Error in delayed weather retry: $e');
          }
        }
      }
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

  void loadRoute() async {
    try {
      final route = await RouteService.loadRoute();
      if (route != null && mounted) {
        setState(() {
          selectedRoute = route;
        });

        debugPrint('Loaded route: ${route['route_name']}');

        // Draw the route on the map if polyline coordinates are available
        if (route['polyline_coordinates'] != null &&
            route['polyline_coordinates'] is List<LatLng>) {
          final coords = route['polyline_coordinates'] as List<LatLng>;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            mapScreenKey.currentState?.animateRouteDrawing(
              const PolylineId('route'),
              coords,
              const Color(0xFFFFCE21),
              8,
            );
            mapScreenKey.currentState?.zoomToBounds(coords);
          });
        } else if (route['origin_coordinates'] != null &&
            route['destination_coordinates'] != null) {
          // Fallback to drawing route from origin to destination
          final origin = route['origin_coordinates'] as LatLng;
          final destination = route['destination_coordinates'] as LatLng;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final coords =
                await PolylineService().generateBetween(origin, destination);
            mapScreenKey.currentState?.animateRouteDrawing(
              const PolylineId('route'),
              coords,
              const Color(0xFFFFCE21),
              8,
            );
            mapScreenKey.currentState?.zoomToBounds(coords);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
    }
  }

  @override
  void dispose() {
    bookingAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadLocation();
      mapScreenKey.currentState?.initializeLocation();
      // Re-run initialization and alerts when app resumes
      _initializeHomeScreen();
      super.didChangeAppLifecycleState(state);
    }
  }

  Future<void> _showBookingConfirmationDialog() async {
    final confirmed = await showAppBookingConfirmationDialog(
      context: context,
    );

    if (confirmed == true) {
      // User confirmed in the dialog
      await _bookingManager.handleBookingConfirmation();
    }
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

  // Add new bottom sheet method for seating preference
  Future<void> _showSeatingPreferenceSheet() async {
    final result = await showSeatingPreferenceBottomSheet(
      context,
      seatingPreference.value,
    );
    if (result != null && mounted) {
      seatingPreference.value = result;
    }
  }

  // Add new bottom sheet method for discount selection
  Future<void> _showDiscountSelectionSheet() async {
    await LocationInputContainer.showDiscountSelectionDialog(
      context: context,
      selectedDiscountSpecification: selectedDiscountSpecification,
      selectedIdImagePath: selectedIdImagePath,
    );

    // Update fare when discount changes
    if (mounted) {
      setState(() {
        currentFare = FareService.calculateDiscountedFare(
            originalFare, selectedDiscountSpecification.value);
      });
    }
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

    final result = await navigateToLocationSearch(
      context,
      isPickup: isPickup,
      routeID: routeId,
      routeDetails: selectedRoute,
      routePolyline: routePolyline,
      pickupOrder: pickupOrder,
      selectedPickUpLocation: selectedPickUpLocation,
      selectedDropOffLocation: selectedDropOffLocation,
    );

    if (result != null) {
      setState(() {
        if (isPickup) {
          selectedPickUpLocation = result;
        } else {
          selectedDropOffLocation = result;
        }
      });
      // Save the updated location to cache
      saveLocation();
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

  /// Clear cached locations from device storage
  void clearCachedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pickup');
    await prefs.remove('dropoff');
    setState(() {
      selectedPickUpLocation = null;
      selectedDropOffLocation = null;
    });
    debugPrint('Cached locations cleared');
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
          skipDistanceCheck:
              true, // Skip distance warning during app initialization
        );
      });
    }
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
            final weatherIconSize = screenWidth * 0.08;

            return Stack(
              children: [
                MapScreen(
                  key: mapScreenKey,
                  pickUpLocation: selectedPickUpLocation?.coordinates,
                  dropOffLocation: selectedDropOffLocation?.coordinates,
                  bottomPadding: isBookingConfirmed
                      ? _bookingSheetExtent
                      : calculateMapPadding(
                            isBookingConfirmed: isBookingConfirmed,
                            bookingStatusContainerHeight:
                                bookingStatusContainerHeight,
                            locationInputContainerHeight:
                                locationInputContainerHeight,
                            isNotificationVisible: isNotificationVisible,
                            notificationHeight: notificationHeight,
                          ) /
                          MediaQuery.of(context).size.height,
                  onLocationUpdated: (loc) => context
                      .read<WeatherProvider>()
                      .fetchWeather(loc.latitude, loc.longitude),
                  onFareUpdated: (fare) {
                    if (mounted) {
                      setState(() {
                        originalFare = fare;
                        currentFare = FareService.calculateDiscountedFare(
                            fare, selectedDiscountSpecification.value);
                      });
                    }
                  },
                  selectedRoute: selectedRoute,
                  routePolyline:
                      selectedRoute?['polyline_coordinates'] as List<LatLng>?,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: responsivePadding,
                  right: responsivePadding,
                  child: HomeHeaderSection(
                    bookingAnimationController: bookingAnimationController,
                    downwardAnimation: _downwardAnimation,
                    routeName: selectedRoute?['route_name'] ?? 'Select Route',
                    onRouteSelectionTap: _showRouteSelection,
                    weatherIconSize: weatherIconSize,
                  ),
                ),
                HomeScreenFAB(
                  mapScreenKey:
                      mapScreenKey as GlobalKey<State<StatefulWidget>>,
                  downwardAnimation: _downwardAnimation,
                  bookingAnimationControllerValue:
                      bookingAnimationController, // Pass the controller directly
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
                  bottomOffset: calculateBottomPadding(
                    isBookingConfirmed: isBookingConfirmed,
                    bookingStatusContainerHeight: bookingStatusContainerHeight,
                    locationInputContainerHeight: locationInputContainerHeight,
                    isNotificationVisible: isNotificationVisible,
                    notificationHeight: notificationHeight,
                  ), // FAB uses the main calculation
                ),
                if (!isBookingConfirmed)
                  Positioned(
                    bottom: bottomNavBarHeight,
                    left: responsivePadding,
                    right: responsivePadding,
                    child: Container(
                      key:
                          locationInputContainerKey, // Assign key here for measurements
                      child: HomeBottomSection(
                        bookingAnimationController: bookingAnimationController,
                        downwardAnimation: _downwardAnimation,
                        isNotificationVisible: isNotificationVisible,
                        notificationHeight: notificationHeight,
                        onNotificationClose: () {
                          setState(() {
                            isNotificationVisible = false;
                          });
                        },
                        onMeasureContainers: measureContainers,
                        isRouteSelected: isRouteSelected,
                        selectedPickUpLocation: selectedPickUpLocation,
                        selectedDropOffLocation: selectedDropOffLocation,
                        currentFare: currentFare,
                        originalFare: originalFare,
                        selectedPaymentMethod: selectedPaymentMethod,
                        selectedDiscountSpecification:
                            selectedDiscountSpecification,
                        seatingPreference: seatingPreference,
                        selectedIdImagePath: selectedIdImagePath,
                        screenWidth: screenWidth,
                        responsivePadding: responsivePadding,
                        onNavigateToLocationSearch: _navigateToLocationSearch,
                        onShowSeatingPreferenceDialog:
                            _showSeatingPreferenceSheet,
                        onShowDiscountSelectionDialog:
                            _showDiscountSelectionSheet,
                        onConfirmBooking: _showBookingConfirmationDialog,
                        onPaymentMethodSelected: (method) {
                          setState(() => selectedPaymentMethod = method);
                        },
                      ),
                    ),
                  ),
                if (isBookingConfirmed)
                  HomeBookingSheet(
                    controller: _bookingSheetController,
                    bookingStatus: bookingStatus,
                    pickupLocation: selectedPickUpLocation,
                    dropoffLocation: selectedDropOffLocation,
                    paymentMethod: selectedPaymentMethod ?? 'Cash',
                    fare: currentFare,
                    bookingManager: _bookingManager,
                    driverName: driverName,
                    plateNumber: plateNumber,
                    vehicleModel: vehicleModel,
                    phoneNumber: phoneNumber,
                    isDriverAssigned: isDriverAssigned,
                    currentLocation: mapScreenKey.currentState?.currentLocation,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
