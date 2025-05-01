import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/screens/paymentMethodScreen.dart';
import 'package:pasada_passenger_app/screens/routeSelection.dart';
import 'package:pasada_passenger_app/widgets/booking_details_container.dart';
import 'package:pasada_passenger_app/widgets/booking_status_container.dart';
import 'package:pasada_passenger_app/widgets/payment_details_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import '../location/locationSearchScreen.dart';

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

  bool get isRouteSelected =>
      selectedRoute != null && selectedRoute!['route_name'] != 'Select Route';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadLocation();
      measureContainer();
    });
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

  void _handleBookingConfirmation() {
    setState(() {
      isBookingConfirmed = true;
    });
    _bookingAnimationController.forward();
  }

  void _handleBookingCancellation() {
    setState(() {
      isBookingConfirmed = false;
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

  void navigateToSearch(BuildContext context, bool isPickup) async {
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => SearchLocationScreen(isPickup: isPickup),
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
        mapScreenKey.currentState?.generatePolylineBetween(
          selectedPickUpLocation!.coordinates,
          selectedDropOffLocation!.coordinates,
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
                MapScreen(
                  key: mapScreenKey,
                  pickUpLocation: selectedPickUpLocation?.coordinates,
                  dropOffLocation: selectedDropOffLocation?.coordinates,
                  bottomPadding: calculateBottomPadding() /
                      MediaQuery.of(context).size.height,
                  onEtaUpdated: (eta) {
                    setState(() => etaText = eta);
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => measureContainer());
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BookingStatusContainer(),
                                BookingDetailsContainer(
                                  pickupLocation: selectedPickUpLocation,
                                  dropoffLocation: selectedDropOffLocation,
                                  etaText: etaText,
                                ),
                                PaymentDetailsContainer(
                                  paymentMethod:
                                      selectedPaymentMethod ?? 'Cash',
                                  fare:
                                      currentFare, // Use the calculated fare instead of hardcoded 150.0
                                  onCancelBooking: _handleBookingCancellation,
                                ),
                              ],
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
                  SizedBox(height: screenWidth * 0.04),
                  InkWell(
                    onTap: isRouteSelected
                        ? () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentMethodScreen(
                                  currentSelection: selectedPaymentMethod,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                            if (result != null && mounted) {
                              setState(() => selectedPaymentMethod = result);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF3D3D3D)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Row(
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
                              color: isRouteSelected
                                  ? (isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212))
                                  : Colors.grey,
                            ),
                          ),
                          const Spacer(),
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
      onTap: enabled ? () => navigateToSearch(context, isPickup) : null,
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
                  etaText,
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
}
