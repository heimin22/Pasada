import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/screens/routeSelection.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:pasada_passenger_app/services/driverAssignmentService.dart';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:pasada_passenger_app/widgets/booking_status_manager.dart';
import 'package:pasada_passenger_app/widgets/loading_dialog.dart';
import 'package:pasada_passenger_app/widgets/onboarding_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import '../location/locationSearchScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:pasada_passenger_app/widgets/location_input_container.dart';
import 'package:pasada_passenger_app/widgets/home_screen_fab.dart';
import 'package:pasada_passenger_app/managers/booking_manager.dart';
import 'package:pasada_passenger_app/widgets/booking_confirmation_dialog.dart';

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

  late AnimationController bookingAnimationController; // Made public
  late Animation<double> _downwardAnimation;
  late Animation<double> _upwardAnimation;

  final ValueNotifier<String> seatingPreference = // Made public
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

  // Instantiate BookingManager
  late BookingManager _bookingManager;

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
  // MOVED TO BookingManager: Future<void> loadActiveBooking() async { ... }

  @override
  void initState() {
    super.initState();
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

    _upwardAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
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

      // await loadActiveBooking();
      await _bookingManager.loadActiveBooking(); // Use BookingManager
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
    bookingAnimationController.dispose();
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

  Future<void> _showSeatingPreferenceDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDarkMode ? const Color(0xFF00CC58) : Colors.green.shade600;
    final unselectedColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final selectedTextColor =
        isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
    final unselectedTextColor = isDarkMode
        ? const Color.fromARGB(255, 153, 153, 153)
        : const Color(0xFF757575);

    await showDialog(
      context: context,
      builder: (context) {
        final tempSeatingPreference =
            ValueNotifier<String>(seatingPreference.value);

        return ValueListenableBuilder<String>(
          valueListenable: tempSeatingPreference,
          builder: (context, currentSelection, child) {
            // Animation states for each button, stored in a map
            final Map<String, bool> pressStates = {
              'Sitting': false,
              'Standing': false,
              'Any': false,
            };

            return StatefulBuilder(
              builder: (BuildContext sctx, StateSetter stateSetter) {
                // sctx to avoid name collision
                return ResponsiveDialog(
                  title: 'Seating Preferences',
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Pili ka, nakaupo ba, nakatayo, o kahit ano?',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212))),
                      const SizedBox(height: 20),
                      AnimatedScale(
                        scale: pressStates['Sitting']! ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentSelection == 'Sitting'
                                ? selectedColor
                                : unselectedColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            tempSeatingPreference.value = 'Sitting';
                            stateSetter(() => pressStates['Sitting'] = true);
                            await Future.delayed(
                                const Duration(milliseconds: 150));
                            stateSetter(() => pressStates['Sitting'] = false);
                          },
                          child: Text('Sitting',
                              style: TextStyle(
                                  color: currentSelection == 'Sitting'
                                      ? selectedTextColor
                                      : unselectedTextColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedScale(
                        scale: pressStates['Standing']! ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentSelection == 'Standing'
                                ? selectedColor
                                : unselectedColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            tempSeatingPreference.value = 'Standing';
                            stateSetter(() => pressStates['Standing'] = true);
                            await Future.delayed(
                                const Duration(milliseconds: 150));
                            stateSetter(() => pressStates['Standing'] = false);
                          },
                          child: Text('Standing',
                              style: TextStyle(
                                  color: currentSelection == 'Standing'
                                      ? selectedTextColor
                                      : unselectedTextColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedScale(
                        scale: pressStates['Any']! ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentSelection == 'Any'
                                ? selectedColor
                                : unselectedColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            tempSeatingPreference.value = 'Any';
                            stateSetter(() => pressStates['Any'] = true);
                            await Future.delayed(
                                const Duration(milliseconds: 150));
                            stateSetter(() => pressStates['Any'] = false);
                          },
                          child: Text('Any',
                              style: TextStyle(
                                  color: currentSelection == 'Any'
                                      ? selectedTextColor
                                      : unselectedTextColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(sctx), // Use sctx here
                      child: Text('Cancel',
                          style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        seatingPreference.value = tempSeatingPreference.value;
                        Navigator.pop(sctx); // Use sctx here
                      },
                      child: Text('Confirm',
                          style: TextStyle(
                              color: selectedTextColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
                    animation: bookingAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_downwardAnimation.value),
                        child: Opacity(
                          opacity: 1 - bookingAnimationController.value,
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
                  bottomOffset:
                      calculateBottomPadding(), // FAB uses the main calculation
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
                                    currentFare: currentFare,
                                    selectedPaymentMethod:
                                        selectedPaymentMethod,
                                    seatingPreference: seatingPreference,
                                    onNavigateToLocationSearch:
                                        _navigateToLocationSearch,
                                    onShowSeatingPreferenceDialog:
                                        _showSeatingPreferenceDialog,
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
                  Positioned(
                    bottom: bottomNavBarHeight,
                    left: responsivePadding,
                    right: responsivePadding,
                    child: AnimatedBuilder(
                      animation: bookingAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -_upwardAnimation.value),
                          child: Opacity(
                            opacity: bookingAnimationController.value,
                            child: Container(
                              key: bookingStatusContainerKey,
                              child: BookingStatusManager(
                                key: ValueKey<String>(bookingStatus),
                                pickupLocation: selectedPickUpLocation,
                                dropoffLocation: selectedDropOffLocation,
                                paymentMethod: selectedPaymentMethod ?? 'Cash',
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

  // MOVED TO BookingManager: void _updateDriverDetails(Map<String, dynamic> driverData) { ... }

  // MOVED TO BookingManager: String _extractField(dynamic data, List<String> keys) { ... }

  // MOVED TO BookingManager: Future<void> _fetchAndUpdateBookingDetails(int bookingId) async { ... }

  // MOVED TO BookingManager: Future<void> _fetchDriverDetails(String driverId) async { ... }

  // MOVED TO BookingManager: void _loadBookingAfterDriverAssignment(int bookingId) { ... }

  // MOVED TO BookingManager: Future<void> _fetchDriverDetailsDirectlyFromDB(int bookingId) async { ... }
}
