import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../network/networkUtilities.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ViewRideDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;
  final int? bookingId;

  const ViewRideDetailsScreen({super.key, this.booking, this.bookingId});

  @override
  State<ViewRideDetailsScreen> createState() => _ViewRideDetailsScreenState();
}

class _ViewRideDetailsScreenState extends State<ViewRideDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic> bookingDetails = {};
  final supabase = Supabase.instance.client;

  // Map-related variables
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  bool isMapReady = false;
  List<LatLng>? routePolyline;

  @override
  void initState() {
    super.initState();

    // Inspect database schema to understand relationships
    _inspectDatabaseSchema();

    if (widget.booking != null) {
      bookingDetails = widget.booking!;
      // Even if we have booking data, fetch additional details
      _fetchAdditionalDetails().then((_) {
        if (mounted) {
          _fetchRouteAndGeneratePolyline();
        }
      });
    } else if (widget.bookingId != null) {
      // Fetch booking details by ID
      fetchBookingDetails(widget.bookingId!).then((_) {
        if (mounted) {
          _fetchRouteAndGeneratePolyline();
        }
      });
    } else {
      // No booking data or ID provided
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchBookingDetails(int bookingId) async {
    try {
      // First, fetch basic booking details without relationships
      final response = await supabase
          .from('bookings')
          .select('*')
          .eq('booking_id', bookingId)
          .single();

      setState(() {
        bookingDetails = response;
        isLoading = false;
      });
      debugPrint('Fetched booking details: $bookingDetails');

      // Then fetch related data separately
      if (bookingDetails['driver_id'] != null) {
        try {
          final driverResponse = await supabase
              .from('driver') // Adjust table name if needed
              .select('full_name, driver_number, vehicle_id')
              .eq('driver_id', bookingDetails['driver_id'])
              .single();

          setState(() {
            bookingDetails['driver_name'] = driverResponse['full_name'];
            bookingDetails['driver_number'] = driverResponse['driver_number'];
          });

          // If we have vehicle_id, fetch vehicle details
          if (driverResponse['vehicle_id'] != null) {
            final vehicleResponse = await supabase
                .from('vehicle')
                .select('plate_number')
                .eq('vehicle_id', driverResponse['vehicle_id'])
                .single();

            setState(() {
              bookingDetails['plate_number'] = vehicleResponse['plate_number'];
            });
          }
        } catch (e) {
          debugPrint('Error fetching driver details: $e');
        }
      }

      // Fetch passenger details
      if (bookingDetails['id'] != null) {
        try {
          final passengerResponse = await supabase
              .from('passenger')
              .select('display_name, contact_number')
              .eq('id', bookingDetails['id'])
              .single();

          setState(() {
            bookingDetails['passenger_name'] =
                passengerResponse['display_name'];
            bookingDetails['contact_number'] =
                passengerResponse['contact_number'];
          });
        } catch (e) {
          debugPrint('Error fetching passenger details: $e');
        }
      }
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAdditionalDetails() async {
    try {
      // If we already have booking data but need additional details
      if (bookingDetails['booking_id'] == null &&
          bookingDetails['id'] != null) {
        bookingDetails['booking_id'] = bookingDetails['id'];
      }

      if (bookingDetails['booking_id'] != null) {
        // Fetch driver details directly if we have driver_id
        if (bookingDetails['driver_id'] != null) {
          try {
            final driverResponse = await supabase
                .from('driverTable')
                .select('full_name, driver_number, vehicle_id')
                .eq('driver_id', bookingDetails['driver_id'])
                .single();

            setState(() {
              bookingDetails['driver_name'] = driverResponse['full_name'];
              bookingDetails['driver_number'] = driverResponse['driver_number'];
            });

            // If we have vehicle_id, fetch vehicle details
            if (driverResponse['vehicle_id'] != null) {
              final vehicleResponse = await supabase
                  .from('vehicleTable')
                  .select('plate_number')
                  .eq('vehicle_id', driverResponse['vehicle_id'])
                  .single();

              setState(() {
                bookingDetails['plate_number'] =
                    vehicleResponse['plate_number'];
              });
            }
          } catch (e) {
            debugPrint('Error fetching driver details: $e');
          }
        }

        // Fetch passenger details if not already included
        if (bookingDetails['id'] != null &&
            bookingDetails['passenger_name'] == null) {
          try {
            final passengerResponse = await supabase
                .from('passenger')
                .select('display_name')
                .eq('id', bookingDetails['id'])
                .single();

            setState(() {
              bookingDetails['passenger_name'] =
                  passengerResponse['display_name'];
            });
          } catch (e) {
            debugPrint('Error fetching passenger details: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching additional details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      Fluttertoast.showToast(
        msg: "Copied to clipboard",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    });
  }

  Future<void> _contactSupport() async {
    // Implementation for contacting support
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contact.pasada@gmail.com',
      queryParameters: {
        'subject':
            'Support Request: Booking ${bookingDetails['booking_id'] ?? bookingDetails['id']}',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        Fluttertoast.showToast(
          msg: 'Could not launch email client',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      Fluttertoast.showToast(
        msg: 'Error contacting support',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Fetch route details and generate polyline
  Future<void> _fetchRouteAndGeneratePolyline() async {
    if (bookingDetails['pickup_lat'] == null ||
        bookingDetails['pickup_lng'] == null ||
        bookingDetails['dropoff_lat'] == null ||
        bookingDetails['dropoff_lng'] == null) {
      debugPrint('Missing coordinates for polyline');
      return;
    }

    try {
      final pickupLatLng = LatLng(
          double.parse(bookingDetails['pickup_lat'].toString()),
          double.parse(bookingDetails['pickup_lng'].toString()));

      final dropoffLatLng = LatLng(
          double.parse(bookingDetails['dropoff_lat'].toString()),
          double.parse(bookingDetails['dropoff_lng'].toString()));

      // Add markers
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
            title: 'Pickup', snippet: bookingDetails['pickup_address']),
      ));

      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
            title: 'Dropoff', snippet: bookingDetails['dropoff_address']),
      ));

      // Check if we have a route_id to fetch the official route
      if (bookingDetails['route_id'] != null) {
        // Fetch the official route details
        final routeResponse = await supabase
            .from('official_routes')
            .select('intermediate_coordinates')
            .eq('officialroute_id', bookingDetails['route_id'])
            .single();

        if (routeResponse['intermediate_coordinates'] != null) {
          var intermediateCoords = routeResponse['intermediate_coordinates'];

          // If it's a string, parse it as JSON
          if (intermediateCoords is String) {
            try {
              intermediateCoords = jsonDecode(intermediateCoords);
            } catch (e) {
              debugPrint('Failed to parse intermediate_coordinates: $e');
            }
          }

          // Generate polyline with intermediate coordinates
          await generateRoutePolyline(intermediateCoords,
              originCoordinates: pickupLatLng,
              destinationCoordinates: dropoffLatLng);
        } else {
          // Fallback to direct route if no intermediate coordinates
          await generatePolylineBetween(pickupLatLng, dropoffLatLng);
        }
      } else {
        // No route_id, generate direct polyline
        await generatePolylineBetween(pickupLatLng, dropoffLatLng);
      }

      if (mounted) {
        setState(() {
          isMapReady = true;
        });
      }
    } catch (e) {
      debugPrint('Error generating polyline: $e');
    }
  }

  // Generate polyline with intermediate coordinates (similar to mapScreen.dart)
  Future<void> generateRoutePolyline(List<dynamic> intermediateCoordinates,
      {LatLng? originCoordinates, LatLng? destinationCoordinates}) async {
    try {
      final hasConnection = await checkNetworkConnection();
      if (!hasConnection) return;

      final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
      if (apiKey.isEmpty) {
        debugPrint('API key not found');
        return;
      }

      final polylinePoints = PolylinePoints();

      // Convert intermediate coordinates to waypoints format
      List<Map<String, dynamic>> intermediates = [];
      if (intermediateCoordinates.isNotEmpty) {
        for (var point in intermediateCoordinates) {
          if (point is Map &&
              point.containsKey('lat') &&
              point.containsKey('lng')) {
            intermediates.add({
              'location': {
                'latLng': {
                  'latitude': double.parse(point['lat'].toString()),
                  'longitude': double.parse(point['lng'].toString())
                }
              }
            });
          }
        }
      }

      // Routes API request
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': originCoordinates?.latitude,
              'longitude': originCoordinates?.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destinationCoordinates?.latitude,
              'longitude': destinationCoordinates?.longitude,
            },
          },
        },
        'intermediates': intermediates,
        'travelMode': 'DRIVE',
        'polylineEncoding': 'ENCODED_POLYLINE',
        'computeAlternativeRoutes': false,
        'routingPreference': 'TRAFFIC_AWARE',
      });

      final response =
          await NetworkUtility.postUrl(uri, headers: headers, body: body);

      if (response == null) {
        debugPrint('No response from the server');
        return;
      }

      final data = json.decode(response);

      // Add response validation
      if (data['routes'] == null || data['routes'].isEmpty) {
        debugPrint('No routes found');
        return;
      }

      // Null checking for nested properties
      final polyline = data['routes'][0]['polyline']?['encodedPolyline'];
      if (polyline == null) {
        debugPrint('No polyline found in the response');
        return;
      }

      // Decode the polyline
      List<PointLatLng> decodedPolyline =
          polylinePoints.decodePolyline(polyline);
      List<LatLng> polylineCoordinates = decodedPolyline
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Store the route polyline for later use
      routePolyline = polylineCoordinates;

      // Update UI with the polyline
      if (mounted) {
        setState(() {
          polylines.clear();
          polylines[const PolylineId('route_path')] = Polyline(
            polylineId: const PolylineId('route_path'),
            points: polylineCoordinates,
            color: const Color(0xFF067837),
            width: 5,
          );
        });
      }
    } catch (e) {
      debugPrint('Error generating route polyline: $e');
    }
  }

  // Generate direct polyline between two points (similar to mapScreen.dart)
  Future<void> generatePolylineBetween(LatLng start, LatLng destination) async {
    try {
      final hasConnection = await checkNetworkConnection();
      if (!hasConnection) return;

      final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
      if (apiKey.isEmpty) {
        debugPrint('API key not found');
        return;
      }

      final polylinePoints = PolylinePoints();

      // Routes API request
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': start.latitude,
              'longitude': start.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'travelMode': 'DRIVE',
        'polylineEncoding': 'ENCODED_POLYLINE',
        'computeAlternativeRoutes': false,
        'routingPreference': 'TRAFFIC_AWARE',
      });

      final response =
          await NetworkUtility.postUrl(uri, headers: headers, body: body);

      if (response == null) {
        debugPrint('No response from the server');
        return;
      }

      final data = json.decode(response);

      // Add response validation
      if (data['routes'] == null || data['routes'].isEmpty) {
        debugPrint('No routes found');
        return;
      }

      // Null checking for nested properties
      final polyline = data['routes'][0]['polyline']?['encodedPolyline'];
      if (polyline == null) {
        debugPrint('No polyline found in the response');
        return;
      }

      // Decode the polyline
      List<PointLatLng> decodedPolyline =
          polylinePoints.decodePolyline(polyline);
      List<LatLng> polylineCoordinates = decodedPolyline
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Store the route polyline for later use
      routePolyline = polylineCoordinates;

      // Update UI with the polyline
      if (mounted) {
        setState(() {
          polylines.clear();
          polylines[const PolylineId('route_path')] = Polyline(
            polylineId: const PolylineId('route_path'),
            points: polylineCoordinates,
            color: const Color(0xFF067837),
            width: 5,
          );
        });
      }
    } catch (e) {
      debugPrint('Error generating polyline: $e');
    }
  }

  // Check network connection
  Future<bool> checkNetworkConnection() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        Fluttertoast.showToast(
          msg: 'No internet connection',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking network connection: $e');
      return false;
    }
  }

  // Helper method to get the center position between pickup and dropoff
  LatLng _getCenterPosition() {
    try {
      if (bookingDetails['pickup_lat'] != null &&
          bookingDetails['pickup_lng'] != null &&
          bookingDetails['dropoff_lat'] != null &&
          bookingDetails['dropoff_lng'] != null) {
        final double pickupLat =
            double.parse(bookingDetails['pickup_lat'].toString());
        final double pickupLng =
            double.parse(bookingDetails['pickup_lng'].toString());
        final double dropoffLat =
            double.parse(bookingDetails['dropoff_lat'].toString());
        final double dropoffLng =
            double.parse(bookingDetails['dropoff_lng'].toString());

        return LatLng(
          (pickupLat + dropoffLat) / 2,
          (pickupLng + dropoffLng) / 2,
        );
      }
    } catch (e) {
      debugPrint('Error calculating center position: $e');
    }

    // Default position if coordinates are not available
    return const LatLng(14.617494, 120.971770); // Default to Manila
  }

  // Helper method to fit the map to show both markers
  void _fitMapToBounds() {
    if (mapController == null || markers.isEmpty) return;

    try {
      // Calculate the bounds that include all markers
      double minLat = 90.0;
      double maxLat = -90.0;
      double minLng = 180.0;
      double maxLng = -180.0;

      for (Marker marker in markers) {
        if (marker.position.latitude < minLat) {
          minLat = marker.position.latitude;
        }
        if (marker.position.latitude > maxLat) {
          maxLat = marker.position.latitude;
        }
        if (marker.position.longitude < minLng) {
          minLng = marker.position.longitude;
        }
        if (marker.position.longitude > maxLng) {
          maxLng = marker.position.longitude;
        }
      }

      // Add padding to the bounds
      final double padding = 0.01;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      // Animate camera to show the bounds
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50, // Padding in pixels
        ),
      );
    } catch (e) {
      debugPrint('Error fitting map to bounds: $e');
    }
  }

  // Helper method to inspect database schema
  Future<void> _inspectDatabaseSchema() async {
    try {
      // Instead of calling custom functions, just log that we're checking schema
      debugPrint(
          'Database schema inspection skipped - using direct table queries');
    } catch (e) {
      debugPrint('Error inspecting database schema: $e');
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        elevation: 0,
        leadingWidth: 60, // Give more space for the back button
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Ride Receipt',
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _contactSupport,
              child: Text(
                'Contact Support',
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        centerTitle: false, // Align title to the left
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00CC58),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver Profile Section (Now at the top)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Details',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Driver Profile Picture (Left side)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),

                              // Driver Details (Right side)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      bookingDetails['driver_name'] ??
                                          'Driver Name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? const Color(0xFFF5F5F5)
                                            : const Color(0xFF121212),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          bookingDetails['driver_number'] ??
                                              'N/A',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      bookingDetails['plate_number'] ??
                                          'Plate Number',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Booking ID and Date Section (Now second)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Booking ID
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking ID',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    bookingDetails['booking_id']?.toString() ??
                                        'N/A',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () => _copyToClipboard(
                                        bookingDetails['booking_id']
                                                ?.toString() ??
                                            ''),
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Booking Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking Date',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                ),
                              ),
                              Text(
                                bookingDetails['created_at'] != null
                                    ? DateTime.parse(
                                            bookingDetails['created_at'])
                                        .toString()
                                        .substring(0, 16)
                                    : 'N/A',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Fare and Payment Section (Third position unchanged)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Total Fare
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Fare',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                ),
                              ),
                              Text(
                                '₱${(bookingDetails['fare'] is num ? bookingDetails['fare'].toDouble() : double.tryParse(bookingDetails['fare']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Seating Preference
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Seating Preference',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                ),
                              ),
                              Text(
                                bookingDetails['seat_type']?.toString() ??
                                    'Standard',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Payment Method
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                ),
                              ),
                              Row(
                                children: [
                                  // Payment method icon
                                  _buildPaymentMethodIcon(
                                      bookingDetails['payment_method']
                                              ?.toString() ??
                                          'Cash'),
                                  const SizedBox(width: 8),
                                  Text(
                                    bookingDetails['payment_method']
                                            ?.toString() ??
                                        'Cash',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Map and Location Section (Fourth position unchanged)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Route',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Map container
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: isLoading || !isMapReady
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map,
                                          size: 50,
                                          color: isDarkMode
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Loading route map...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _getCenterPosition(),
                                      zoom: 13,
                                    ),
                                    markers: markers,
                                    polylines:
                                        Set<Polyline>.of(polylines.values),
                                    onMapCreated:
                                        (GoogleMapController controller) {
                                      mapController = controller;
                                      // Apply map styling based on theme
                                      if (isDarkMode) {
                                        controller.setMapStyle('''[
                                      {
                                        "elementType": "geometry",
                                        "stylers": [{"color": "#242f3e"}]
                                      },
                                      {
                                        "elementType": "labels.text.fill",
                                        "stylers": [{"color": "#746855"}]
                                      },
                                      {
                                        "elementType": "labels.text.stroke",
                                        "stylers": [{"color": "#242f3e"}]
                                      },
                                      {
                                        "featureType": "road",
                                        "elementType": "geometry",
                                        "stylers": [{"color": "#38414e"}]
                                      },
                                      {
                                        "featureType": "road",
                                        "elementType": "geometry.stroke",
                                        "stylers": [{"color": "#212a37"}]
                                      },
                                      {
                                        "featureType": "road",
                                        "elementType": "labels.text.fill",
                                        "stylers": [{"color": "#9ca5b3"}]
                                      }
                                    ]''');
                                      }

                                      // Fit the map to show both markers and the polyline
                                      _fitMapToBounds();
                                    },
                                    zoomControlsEnabled: false,
                                    scrollGesturesEnabled: false,
                                    zoomGesturesEnabled: false,
                                    rotateGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                    mapToolbarEnabled: false,
                                    myLocationEnabled: false,
                                    myLocationButtonEnabled: false,
                                    compassEnabled: false,
                                  ),
                          ),

                          const SizedBox(height: 20),

                          // Pickup and dropoff locations
                          Row(
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 14,
                                    color: isDarkMode
                                        ? const Color(0xFFF5F5F5)
                                        : const Color(0xFF121212),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 30,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: isDarkMode
                                        ? const Color(0xFFF5F5F5)
                                        : const Color(0xFF121212),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookingDetails['pickup_address'] ??
                                          'Pickup Location',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      bookingDetails['dropoff_address'] ??
                                          'Dropoff Location',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const selectionScreen()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00CC58),
            foregroundColor: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'Back to Home',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'GCash':
        return SvgPicture.asset(
          'assets/svg/gcash_logo.svg',
          width: 24,
          height: 24,
        );
      case 'PayMaya':
      case 'Maya':
        return SvgPicture.asset(
          'assets/svg/maya_logo.svg',
          width: 24,
          height: 24,
        );
      case 'Cash':
        return const Icon(
          Icons.money_rounded,
          color: Color(0xFF00CC58),
          size: 24,
        );
      default:
        return const Icon(
          Icons.payment,
          color: Color(0xFF00CC58),
          size: 24,
        );
    }
  }
}
