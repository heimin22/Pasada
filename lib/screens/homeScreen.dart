import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/managers/booking_manager.dart';
import 'package:pasada_passenger_app/providers/weather_provider.dart';
import 'package:pasada_passenger_app/screens/calendar_screen.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:pasada_passenger_app/services/calendar_service.dart';
import 'package:pasada_passenger_app/services/driverAssignmentService.dart';
import 'package:pasada_passenger_app/services/error_logging_service.dart';
import 'package:pasada_passenger_app/services/fare_service.dart';
import 'package:pasada_passenger_app/services/home_screen_init_service.dart';
import 'package:pasada_passenger_app/services/location_weather_service.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';
import 'package:pasada_passenger_app/services/route_service.dart';
import 'package:pasada_passenger_app/utils/exception_handler.dart';
import 'package:pasada_passenger_app/utils/home_screen_navigation.dart';
import 'package:pasada_passenger_app/utils/home_screen_utils.dart';
import 'package:pasada_passenger_app/widgets/alert_sequence_dialog.dart';
import 'package:pasada_passenger_app/widgets/booking_confirmation_dialog.dart';
import 'package:pasada_passenger_app/widgets/bounds_fab.dart';
import 'package:pasada_passenger_app/widgets/discount_selection_dialog.dart';
import 'package:pasada_passenger_app/widgets/holiday_banner.dart';
import 'package:pasada_passenger_app/widgets/home_booking_sheet.dart';
import 'package:pasada_passenger_app/widgets/home_bottom_section.dart';
import 'package:pasada_passenger_app/widgets/home_header_section.dart';
import 'package:pasada_passenger_app/widgets/home_screen_fab.dart';
import 'package:pasada_passenger_app/widgets/refreshable_bottom_sheet.dart';
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

  // Debounce timer for bottom sheet reopening
  Timer? _bottomSheetDebounce;
  // Refreshable bottom sheet state for content refresh
  RefreshableBottomSheetState? _refreshableBottomSheetState;
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
  bool showHolidayBanner = false;

  double currentFare = 0.0;
  double originalFare = 0.0; // Store original fare before discount

  // ValueNotifiers for optimized rebuilds
  final ValueNotifier<SelectedLocation?> _pickupLocationNotifier =
      ValueNotifier(null);
  final ValueNotifier<SelectedLocation?> _dropoffLocationNotifier =
      ValueNotifier(null);
  final ValueNotifier<double> _fareNotifier = ValueNotifier(0.0);
  final ValueNotifier<String?> _paymentMethodNotifier = ValueNotifier(null);
  final ValueNotifier<Map<String, dynamic>?> _routeNotifier =
      ValueNotifier(null);
  final ValueNotifier<bool> _notificationVisibilityNotifier =
      ValueNotifier(true);
  final ValueNotifier<bool> _holidayBannerNotifier = ValueNotifier(false);
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
  final ValueNotifier<String?> selectedIdImageUrl = // Made public
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

  // Vehicle capacity from driver's vehicle
  int? vehicleTotalCapacity;
  int? vehicleSittingCapacity;
  int? vehicleStandingCapacity;
  int capacityRefreshTick =
      0; // forces rebuilds on manual/auto capacity refresh

  // Add a state variable to track booking status
  String bookingStatus = 'requested';

  // Instantiate BookingManager
  late BookingManager _bookingManager;

  Future<void> _showRouteSelection() async {
    final result = await navigateToRouteSelection(context);

    if (result != null && mounted) {
      _routeNotifier.value = result;
      _pickupLocationNotifier.value = null;
      _dropoffLocationNotifier.value = null;

      // Update the actual variables for backward compatibility
      selectedRoute = result;
      selectedPickUpLocation = null;
      selectedDropOffLocation = null;

      // Clear map pins and overlays when switching routes
      mapScreenKey.currentState?.clearAll();

      // Clear cached locations so user selects anew for the new route
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pickup');
        await prefs.remove('dropoff');
      } catch (_) {}

      // Save the route for persistence
      await RouteService.saveRoute(result);

      // Make sure we have the route ID
      if (result['officialroute_id'] == null) {
        try {
          final routeResponse = await Supabase.instance.client
              .from('official_routes')
              .select('officialroute_id')
              .eq('route_name', result['route_name'])
              .single();

          selectedRoute!['officialroute_id'] =
              routeResponse['officialroute_id'];
          _routeNotifier.value = selectedRoute;
        } catch (e) {
          ExceptionHandler.handleDatabaseException(
            e,
            'HomeScreen.loadRoute',
            userMessage: 'Failed to retrieve route ID',
            showToast: false,
          );
          ErrorLoggingService.logError(
            error: e.toString(),
            context: 'HomeScreen.loadRoute',
          );
        }
      }

      // Get origin and destination coordinates
      LatLng? originCoordinates = result['origin_coordinates'];
      LatLng? destinationCoordinates = result['destination_coordinates'];

      // Draw the route only when not in an active ride
      if (bookingStatus == 'requested') {
        // Show bounds only. Do not draw selection polyline.
        if (result['polyline_coordinates'] != null &&
            result['polyline_coordinates'] is List<LatLng>) {
          final coords = result['polyline_coordinates'] as List<LatLng>;
          mapScreenKey.currentState?.zoomToBounds(coords);
        } else if (originCoordinates != null &&
            destinationCoordinates != null) {
          final coords = await PolylineService()
              .generateBetween(originCoordinates, destinationCoordinates);
          mapScreenKey.currentState?.zoomToBounds(coords);
        }
      }
    }
  }

  Future<void> _showCalendarScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarScreen(),
      ),
    );
  }

  /// Update yung proper location base duon sa search type
  void updateLocation(SelectedLocation location, bool isPickup) {
    if (isPickup) {
      selectedPickUpLocation = location;
      _pickupLocationNotifier.value = location;
    } else {
      selectedDropOffLocation = location;
      _dropoffLocationNotifier.value = location;
    }
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
        _notificationVisibilityNotifier.value = false;
        measureContainers();
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
    if (mounted) {
      selectedPaymentMethod = savedMethod ?? 'Cash';
      _paymentMethodNotifier.value = selectedPaymentMethod;
    }
  }

  void loadRoute() async {
    try {
      final route = await RouteService.loadRoute();
      if (route != null && mounted) {
        selectedRoute = route;
        _routeNotifier.value = route;

        debugPrint('Loaded route: ${route['route_name']}');

        // Show bounds only when not in an active ride; do not draw selection polyline
        if (bookingStatus == 'requested') {
          if (route['polyline_coordinates'] != null &&
              route['polyline_coordinates'] is List<LatLng>) {
            final coords = route['polyline_coordinates'] as List<LatLng>;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapScreenKey.currentState?.zoomToBounds(coords);
            });
          } else if (route['origin_coordinates'] != null &&
              route['destination_coordinates'] != null) {
            final origin = route['origin_coordinates'] as LatLng;
            final destination = route['destination_coordinates'] as LatLng;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final coords =
                  await PolylineService().generateBetween(origin, destination);
              mapScreenKey.currentState?.zoomToBounds(coords);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
    }
  }

  @override
  void dispose() {
    _bottomSheetDebounce?.cancel();
    bookingAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // Dispose ValueNotifiers
    _pickupLocationNotifier.dispose();
    _dropoffLocationNotifier.dispose();
    _fareNotifier.dispose();
    _paymentMethodNotifier.dispose();
    _routeNotifier.dispose();
    _notificationVisibilityNotifier.dispose();
    _holidayBannerNotifier.dispose();

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

  // Method to update fare when discount changes
  void _updateFareForDiscount() async {
    if (!mounted) return;
    final String discount = selectedDiscountSpecification.value;
    // Update holiday banner visibility asynchronously
    _updateHolidayBannerVisibility(discount);

    // Use holiday-aware fare calculation
    final discountedFare = await FareService.calculateDiscountedFareWithHoliday(
        originalFare, selectedDiscountSpecification.value);

    if (mounted) {
      currentFare = discountedFare;
      _fareNotifier.value = currentFare;
    }
  }

  Future<void> _updateHolidayBannerVisibility(String discount) async {
    if (discount.toLowerCase() == 'student') {
      final bool isHoliday =
          await CalendarService.instance.isPhilippineHoliday(DateTime.now());
      if (!mounted) return;
      showHolidayBanner = isHoliday;
      _holidayBannerNotifier.value = isHoliday;
    } else {
      if (!mounted) return;
      showHolidayBanner = false;
      _holidayBannerNotifier.value = false;
    }
  }

  // Add new bottom sheet method for discount selection
  Future<void> _showDiscountSelectionSheet() async {
    await DiscountSelectionDialog.show(
      context: context,
      selectedDiscountSpecification: selectedDiscountSpecification,
      selectedIdImageUrl: selectedIdImageUrl,
      onFareUpdated: _updateFareForDiscount, // Pass the fare update callback
      onReopenMainBottomSheet: _reopenBottomSheetAfterLocationUpdate,
      refreshableBottomSheetState:
          _refreshableBottomSheetState, // Pass refreshable state
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
      if (isPickup) {
        selectedPickUpLocation = result;
        _pickupLocationNotifier.value = result;
      } else {
        selectedDropOffLocation = result;
        _dropoffLocationNotifier.value = result;
      }
      // Save the updated location to cache
      saveLocation();
      WidgetsBinding.instance.addPostFrameCallback((_) => measureContainers());

      // Reopen the bottom sheet with updated location and fare values
      _reopenBottomSheetAfterLocationUpdate();
    }
  }

  /// Reopens the bottom sheet with updated location and fare values
  void _reopenBottomSheetAfterLocationUpdate() {
    // Cancel any existing debounce timer
    _bottomSheetDebounce?.cancel();

    // Close any existing bottom sheet first (if there is one)
    final navigatorState = Navigator.of(context);
    if (navigatorState.canPop()) {
      navigatorState.pop();
    }

    // Set up debounced bottom sheet reopening
    _bottomSheetDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showRefreshableBottomSheet();
      }
    });
  }

  /// Shows the refreshable bottom sheet
  Future<void> _showRefreshableBottomSheet() async {
    final result = await RefreshableBottomSheet.showRefreshableBottomSheet(
      context: context,
      isRouteSelected: isRouteSelected,
      selectedPickUpLocation: selectedPickUpLocation,
      selectedDropOffLocation: selectedDropOffLocation,
      currentFare: currentFare,
      originalFare: originalFare,
      selectedPaymentMethod: selectedPaymentMethod,
      selectedDiscountSpecification: selectedDiscountSpecification,
      seatingPreference: seatingPreference,
      selectedIdImageUrl: selectedIdImageUrl,
      onNavigateToLocationSearch: _navigateToLocationSearch,
      onShowSeatingPreferenceDialog: _showSeatingPreferenceSheet,
      onShowDiscountSelectionDialog: _showDiscountSelectionSheet,
      onConfirmBooking: () => _bookingManager.handleBookingConfirmation(),
      onFareUpdated: _updateFareForDiscount,
    );

    // Store the state for content refresh
    _refreshableBottomSheetState = result;
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
    selectedPickUpLocation = null;
    selectedDropOffLocation = null;
    _pickupLocationNotifier.value = null;
    _dropoffLocationNotifier.value = null;
    debugPrint('Cached locations cleared');
  }

  void loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final pickupJson = prefs.getString('pickup');
    if (pickupJson != null) {
      selectedPickUpLocation =
          SelectedLocation.fromJson(jsonDecode(pickupJson));
      _pickupLocationNotifier.value = selectedPickUpLocation;
    }
    final dropoffJson = prefs.getString('dropoff');
    if (dropoffJson != null) {
      selectedDropOffLocation =
          SelectedLocation.fromJson(jsonDecode(dropoffJson));
      _dropoffLocationNotifier.value = selectedDropOffLocation;
    }
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
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenWidth < 400 || screenHeight < 700;

            // Responsive sizing based on screen size
            final responsivePadding =
                isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.05;
            final fabIconSize =
                isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.06;
            final bottomNavBarHeight = isSmallScreen ? 15.0 : 20.0;
            final fabVerticalSpacing = isSmallScreen ? 8.0 : 10.0;
            final weatherIconSize =
                isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.08;

            return Stack(
              children: [
                if (showHolidayBanner)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: responsivePadding,
                    right: responsivePadding,
                    child: HolidayBanner(
                      message:
                          'Holiday today: Student discounts are not available.',
                      onClose: () {
                        showHolidayBanner = false;
                        _holidayBannerNotifier.value = false;
                      },
                    ),
                  ),
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
                  onFareUpdated: (fare) async {
                    if (!mounted) return;
                    final String discount = selectedDiscountSpecification.value;
                    final double discounted =
                        await FareService.calculateDiscountedFareWithHoliday(
                            fare, discount);
                    if (!mounted) return;
                    originalFare = fare;
                    currentFare = discounted;
                    _fareNotifier.value = currentFare;
                  },
                  selectedRoute: selectedRoute,
                  routePolyline:
                      selectedRoute?['polyline_coordinates'] as List<LatLng>?,
                  bookingStatus: bookingStatus,
                ),
                Positioned(
                  top: (MediaQuery.of(context).padding.top + 10) +
                      (showHolidayBanner ? 58 : 0),
                  left: responsivePadding,
                  right: responsivePadding,
                  child: HomeHeaderSection(
                    bookingAnimationController: bookingAnimationController,
                    downwardAnimation: _downwardAnimation,
                    routeName: selectedRoute?['route_name'] ?? 'Select Route',
                    onRouteSelectionTap: _showRouteSelection,
                    weatherIconSize: weatherIconSize,
                    onCalendarTap: _showCalendarScreen,
                  ),
                ),
                if (!(isBookingConfirmed &&
                    (bookingStatus == 'accepted' ||
                        bookingStatus == 'ongoing')))
                  HomeScreenFAB(
                    mapScreenKey:
                        mapScreenKey as GlobalKey<State<StatefulWidget>>,
                    downwardAnimation: _downwardAnimation,
                    bookingAnimationControllerValue:
                        bookingAnimationController, // Pass the controller directly
                    responsivePadding: responsivePadding,
                    fabVerticalSpacing: fabVerticalSpacing,
                    iconSize: fabIconSize,
                    bookingStatus: bookingStatus,
                    isBookingConfirmed: isBookingConfirmed,
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
                    bottomOffset: isBookingConfirmed
                        // When confirmed, track the draggable bottom sheet extent responsively
                        ? (_bookingSheetExtent * screenHeight) + 20.0
                        : calculateBottomPadding(
                            isBookingConfirmed: isBookingConfirmed,
                            bookingStatusContainerHeight:
                                bookingStatusContainerHeight,
                            locationInputContainerHeight:
                                locationInputContainerHeight,
                            isNotificationVisible: isNotificationVisible,
                            notificationHeight: notificationHeight,
                          ),
                  ),
                if (!isBookingConfirmed)
                  Positioned(
                    bottom: bottomNavBarHeight,
                    left: responsivePadding,
                    right: responsivePadding,
                    child: Container(
                      key:
                          locationInputContainerKey, // Assign key here for measurements
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _notificationVisibilityNotifier,
                        builder: (context, isNotificationVisible, child) {
                          return ValueListenableBuilder<SelectedLocation?>(
                            valueListenable: _pickupLocationNotifier,
                            builder: (context, selectedPickUpLocation, child) {
                              return ValueListenableBuilder<SelectedLocation?>(
                                valueListenable: _dropoffLocationNotifier,
                                builder:
                                    (context, selectedDropOffLocation, child) {
                                  return ValueListenableBuilder<double>(
                                    valueListenable: _fareNotifier,
                                    builder: (context, currentFare, child) {
                                      return ValueListenableBuilder<String?>(
                                        valueListenable: _paymentMethodNotifier,
                                        builder: (context,
                                            selectedPaymentMethod, child) {
                                          return ValueListenableBuilder<
                                              Map<String, dynamic>?>(
                                            valueListenable: _routeNotifier,
                                            builder: (context, selectedRoute,
                                                child) {
                                              return HomeBottomSection(
                                                bookingAnimationController:
                                                    bookingAnimationController,
                                                downwardAnimation:
                                                    _downwardAnimation,
                                                isNotificationVisible:
                                                    isNotificationVisible,
                                                notificationHeight:
                                                    notificationHeight,
                                                onNotificationClose: () {
                                                  _notificationVisibilityNotifier
                                                      .value = false;
                                                },
                                                onMeasureContainers:
                                                    measureContainers,
                                                isRouteSelected:
                                                    selectedRoute != null &&
                                                        selectedRoute[
                                                                'route_name'] !=
                                                            'Select Route',
                                                selectedPickUpLocation:
                                                    selectedPickUpLocation,
                                                selectedDropOffLocation:
                                                    selectedDropOffLocation,
                                                currentFareNotifier:
                                                    _fareNotifier,
                                                originalFare: originalFare,
                                                selectedPaymentMethod:
                                                    selectedPaymentMethod,
                                                selectedDiscountSpecification:
                                                    selectedDiscountSpecification,
                                                seatingPreference:
                                                    seatingPreference,
                                                selectedIdImageUrl:
                                                    selectedIdImageUrl,
                                                screenWidth: screenWidth,
                                                responsivePadding:
                                                    responsivePadding,
                                                onNavigateToLocationSearch:
                                                    _navigateToLocationSearch,
                                                onShowSeatingPreferenceDialog:
                                                    _showSeatingPreferenceSheet,
                                                onShowDiscountSelectionDialog:
                                                    _showDiscountSelectionSheet,
                                                onConfirmBooking:
                                                    _showBookingConfirmationDialog,
                                                onFareUpdated:
                                                    _updateFareForDiscount,
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
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
                    bookingId: activeBookingId,
                    selectedDiscount:
                        selectedDiscountSpecification.value.isNotEmpty &&
                                selectedDiscountSpecification.value != 'None'
                            ? selectedDiscountSpecification.value
                            : null,
                    capturedImageUrl: selectedIdImageUrl.value,
                    vehicleTotalCapacity: vehicleTotalCapacity,
                    vehicleSittingCapacity: vehicleSittingCapacity,
                    vehicleStandingCapacity: vehicleStandingCapacity,
                    onRefreshCapacity: activeBookingId == null
                        ? null
                        : () => _bookingManager
                            .refreshDriverAndCapacity(activeBookingId!),
                    capacityRefreshTick: capacityRefreshTick,
                    boundsButton: (bookingStatus == 'accepted' ||
                            bookingStatus == 'ongoing')
                        ? BoundsFAB(
                            heroTag: "sheetBoundsFAB",
                            onPressed: () {
                              (mapScreenKey.currentState as dynamic)
                                  ?.showDriverFocusBounds(bookingStatus);
                            },
                            iconSize: fabIconSize,
                            buttonSize:
                                MediaQuery.of(context).size.width * 0.12,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFFF5F5F5),
                            iconColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF00E865)
                                    : const Color(0xFF00CC58),
                          )
                        : null,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
