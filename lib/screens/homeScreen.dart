import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:pasada_passenger_app/services/driverAssignmentService.dart';
import 'package:pasada_passenger_app/widgets/booking_status_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/widgets/location_input_container.dart';
import 'package:pasada_passenger_app/widgets/home_screen_fab.dart';
import 'package:pasada_passenger_app/managers/booking_manager.dart';
import 'package:pasada_passenger_app/widgets/booking_confirmation_dialog.dart';
import 'package:pasada_passenger_app/widgets/seating_preference_sheet.dart';
import 'package:pasada_passenger_app/widgets/route_selection_widget.dart';
import 'package:pasada_passenger_app/widgets/notification_container.dart';
import 'package:pasada_passenger_app/utils/home_screen_utils.dart';
import 'package:pasada_passenger_app/utils/home_screen_navigation.dart';
import 'package:pasada_passenger_app/services/home_screen_init_service.dart';
import 'package:pasada_passenger_app/services/location_weather_service.dart';
import 'package:pasada_passenger_app/widgets/alert_sequence_dialog.dart';
import 'package:pasada_passenger_app/widgets/rush_hour_dialog.dart';
import 'package:pasada_passenger_app/widgets/weather_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pasada_passenger_app/providers/weather_provider.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';

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
  // Controller and current extent for booking bottom sheet
  final DraggableScrollableController _bookingSheetController =
      DraggableScrollableController();
  double _bookingSheetExtent = 0.4;

  late AnimationController bookingAnimationController; // Made public
  late Animation<double> _downwardAnimation;

  final ValueNotifier<String> seatingPreference = // Made public
      ValueNotifier<String>('Sitting');

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
        selectedPickUpLocation = null;
        selectedDropOffLocation = null;
      });

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

  /// Initialize core resources, then fetch weather and display dialogs after loading
  Future<void> _initializeHomeScreen() async {
    // Boot and load core resources first
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
    );
    // Fetch and subscribe to weather updates based on device location
    await LocationWeatherService.fetchAndSubscribe(
      context.read<WeatherProvider>(),
    );

    // Show startup alerts only once
    if (!_hasShownStartupAlerts) {
      final List<Widget> alertPages = [];
      // Rush hour condition
      final nowUtc = DateTime.now().toUtc();
      final nowPH = nowUtc.add(const Duration(hours: 8));
      final minutesSinceMidnight = nowPH.hour * 60 + nowPH.minute;
      const morningStart = 6 * 60;
      const morningEnd = 7 * 60 + 30;
      const eveningStart = 16 * 60 + 30;
      const eveningEnd = 19 * 60 + 30;
      if ((minutesSinceMidnight >= morningStart &&
              minutesSinceMidnight <= morningEnd) ||
          (minutesSinceMidnight >= eveningStart &&
              minutesSinceMidnight <= eveningEnd)) {
        alertPages.add(const RushHourDialogContent());
      }
      // Rain condition
      if (context.read<WeatherProvider>().isRaining) {
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
    }
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
    );

    if (result != null) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: bookingAnimationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -_downwardAnimation.value),
                            child: Opacity(
                              opacity: 1 - bookingAnimationController.value,
                              child: RouteSelectionWidget(
                                routeName: selectedRoute?['route_name'] ??
                                    'Select Route',
                                onTap: _showRouteSelection,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<WeatherProvider>(
                        builder: (context, weatherProv, _) {
                          if (weatherProv.isLoading) {
                            return SizedBox(
                              width: weatherIconSize,
                              height: weatherIconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00CC58),
                              ),
                            );
                          } else if (weatherProv.weather != null) {
                            return Image.network(
                              weatherProv.weather!.iconUrl,
                              width: weatherIconSize,
                              height: weatherIconSize,
                            );
                          } else {
                            return SizedBox(
                                width: weatherIconSize,
                                height: weatherIconSize);
                          }
                        },
                      ),
                    ],
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
                    child: AnimatedBuilder(
                      animation: bookingAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _downwardAnimation.value),
                          child: Opacity(
                            opacity: 1 - bookingAnimationController.value,
                            child: Column(
                              key: locationInputContainerKey, // Assign key here
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNotificationVisible)
                                  NotificationContainer(
                                    downwardAnimation: _downwardAnimation,
                                    notificationHeight: notificationHeight,
                                    onClose: () {
                                      setState(() {
                                        isNotificationVisible = false;
                                      });
                                      measureContainers();
                                    },
                                  ),
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
                                    currentFare: currentFare,
                                    selectedPaymentMethod:
                                        selectedPaymentMethod,
                                    seatingPreference: seatingPreference,
                                    onNavigateToLocationSearch:
                                        _navigateToLocationSearch,
                                    onShowSeatingPreferenceDialog:
                                        _showSeatingPreferenceSheet,
                                    onConfirmBooking:
                                        _showBookingConfirmationDialog,
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
                  DraggableScrollableSheet(
                    controller: _bookingSheetController,
                    initialChildSize: 0.4,
                    minChildSize: 0.2,
                    maxChildSize: 0.75,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: BookingStatusManager(
                                  key: ValueKey<String>(bookingStatus),
                                  pickupLocation: selectedPickUpLocation,
                                  dropoffLocation: selectedDropOffLocation,
                                  paymentMethod:
                                      selectedPaymentMethod ?? 'Cash',
                                  fare: currentFare,
                                  onCancelBooking:
                                      _bookingManager.handleBookingCancellation,
                                  driverName: driverName,
                                  plateNumber: plateNumber,
                                  vehicleModel: vehicleModel,
                                  phoneNumber: phoneNumber,
                                  isDriverAssigned: isDriverAssigned,
                                  bookingStatus: bookingStatus,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
