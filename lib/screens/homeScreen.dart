import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'package:pasada_passenger_app/screens/paymentMethodScreen.dart';
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

class HomeScreenPageState extends State<HomeScreenStateful> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final GlobalKey containerKey = GlobalKey(); // container key for the location container
  double containerHeight = 0.0; // container height idk might reimplement this
  final GlobalKey<MapScreenState> mapScreenKey =
      GlobalKey<MapScreenState>(); // global key para maaccess si MapScreenState
  SelectedLocation? selectedPickUpLocation; // variable for the selected pick up location
  SelectedLocation? selectedDropOffLocation; // variable for the selected drop off location
  String etaText = '--'; // eta text variable placeholder yung "--"
  bool isSearchingPickup = true; // true = pick-up, false - drop-off
  DateTime? lastBackPressTime;
  // keep state alive my nigger
  @override
  bool get wantKeepAlive => true;

  // state variable for the payment method
  String? selectedPaymentMethod;
  final double iconSize = 24;

  // method para sa pagsplit ng location names from landmark to address
  List<String> splitLocation(String location) {
    final List<String> parts = location.split(','); // split by comma
    if (parts.length < 2) return [location, '']; // kapag exact address si location then leave as is
    return [parts[0], parts.sublist(1).join(', ')]; // sa unahan o ibabaw yung landmark which is yung parts[0] the rest is sa baba which is yung parts.sublist(1). tapos join(',')  na lang
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
    // magmemeasure dapat ito after ng first frame
    // WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // load saved locations on initializations
      loadLocation();
      measureContainer();
    });
  }

  @override
  void dispose() {
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
    final result = await Navigator.of(
        context, rootNavigator: true).push(
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
          // final screenHeight = constraints.maxHeight;
          final responsivePadding = screenWidth * 0.05;
          final iconSize = screenWidth * 0.06;
          final bottomNavBarHeight = 20.0;
          final double fabVerticalSpacing = 10.0;
          return Stack(
            children: [
              MapScreen(
                key: mapScreenKey,
                pickUpLocation: selectedPickUpLocation?.coordinates,
                dropOffLocation: selectedDropOffLocation?.coordinates,
                bottomPadding: (containerHeight + bottomNavBarHeight) /
                    MediaQuery.of(context).size.height,
                onEtaUpdated: (eta) {
                  setState(() => etaText = eta);
                  WidgetsBinding.instance.addPostFrameCallback((_) => measureContainer());
                },
              ),
              Positioned(
                bottom: bottomNavBarHeight,
                left: responsivePadding,
                right: responsivePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Location FAB
                    LocationFAB(
                      heroTag: "homeLocationFAB",
                      onPressed: () {
                        final mapState = mapScreenKey.currentState;
                        if (mapState != null &&
                            mapState.currentLocation != null) {
                          mapState.animateToLocation(mapState.currentLocation!);
                        }
                      },
                      iconSize: iconSize,
                      buttonSize: screenWidth * 0.12,
                    ),
                    SizedBox(height: fabVerticalSpacing),
                    // Location Container
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
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
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
              screenWidth, iconSize),
          const Divider(),
          buildLocationRow(svgAssetDropOff, selectedDropOffLocation, false,
              screenWidth, iconSize),
          SizedBox(height: screenWidth * 0.04),
          // payment method widget
          InkWell(
            onTap: () async {
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
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.payment, size: iconSize, color: Color(0xFF00CC58)),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    selectedPaymentMethod ?? 'Select Payment Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF121212),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: iconSize, color: Color(0xFF515151)),
                ],
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.05),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedPickUpLocation != null && selectedDropOffLocation != null && selectedPaymentMethod != null)
              ? () {
                // TODO: Lalagyan na to ng function sa susunod nigga
              }
              : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00CC58),
                disabledBackgroundColor: Color(0xFFD3D3D3),
                foregroundColor: Color(0xFFF5F5F5),
                disabledForegroundColor: Color(0xFFF5F5F5),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm Booking',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  // color: Color(0xFFF5F5F5),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildLocationRow(String svgAsset, SelectedLocation? location,
      bool isPickup, double screenWidth, double iconSize) {
    double iconSize = isPickup ? 15 : 15;
    // split address into two parts
    List<String> locationParts = location != null ? splitLocation(location.address) : ['' , ''];

    return InkWell(
      onTap: () => navigateToSearch(context, isPickup),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPickup) ...[
            Row(
              children: [
                Text(
                  "Total Fare: ",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF121212),
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
                    color: Color(0xFF121212),
                  ),
                ),
                Text(
                  etaText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF515151),
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
                    /// Landmark
                    Text(
                      location != null
                          ? locationParts[0]
                          : (isPickup ? 'Pick-up location' : 'Drop-off location'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF121212),
                      ),
                    ),
                    /// Address
                    if (locationParts[1].isNotEmpty) ...[
                      Text(
                        locationParts[1],
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF515151),
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
}
