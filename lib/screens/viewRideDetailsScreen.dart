import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      bookingDetails = widget.booking!;
      // Even if we have booking data, fetch additional details
      _fetchAdditionalDetails();
    } else if (widget.bookingId != null) {
      // Fetch booking details by ID
      fetchBookingDetails(widget.bookingId!);
    } else {
      // No booking data or ID provided
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchBookingDetails(int bookingId) async {
    try {
      // Fetch booking details from Supabase
      final response = await supabase.from('bookings').select('''
            *,
            passenger:id(display_name, contact_number),
            driverTable:driver_id(name, driver_number, vehicle_id),
            vehicleTable:vehicle_id(plate_number)
          ''').eq('booking_id', bookingId).single();

      setState(() {
        bookingDetails = response;
        isLoading = false;
      });
      debugPrint('Fetched booking details: $bookingDetails');
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
        // Fetch driver and vehicle details if not already included
        if (bookingDetails['driver_name'] == null ||
            bookingDetails['vehicle_details'] == null ||
            bookingDetails['plate_number'] == null) {
          final response = await supabase.from('bookings').select('''
                driver:driver_id(name, phone_number, vehicle_id),
                vehicle:driver(vehicle:vehicle_id(model, plate_number))
              ''').eq('booking_id', bookingDetails['booking_id']).single();

          // Update booking details with driver and vehicle info
          if (response['driver'] != null) {
            bookingDetails['driver_name'] = response['driver']['name'];
            bookingDetails['driver_phone'] = response['driver']['phone_number'];
          }

          if (response['vehicle'] != null &&
              response['vehicle']['vehicle'] != null) {
            bookingDetails['vehicle_details'] =
                response['vehicle']['vehicle']['model'];
            bookingDetails['plate_number'] =
                response['vehicle']['vehicle']['plate_number'];
          }
        }

        // Fetch passenger details if not already included
        if (bookingDetails['passenger_name'] == null) {
          final passengerResponse = await supabase
              .from('passenger')
              .select('name')
              .eq('id', bookingDetails['passenger_id'])
              .single();

          bookingDetails['passenger_name'] = passengerResponse['name'];
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
                              bookingDetails['booking_id']?.toString() ?? 'N/A',
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
                                  bookingDetails['booking_id']?.toString() ??
                                      ''),
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ],
                        ),
                      ],
                    ),

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
                              ? DateTime.parse(bookingDetails['created_at'])
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

                    const SizedBox(height: 40),

                    // Driver Profile Section
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
                            crossAxisAlignment: CrossAxisAlignment
                                .end, // Align text to the right
                            children: [
                              Text(
                                bookingDetails['driverTable']?['full_name'] ??
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
                              Text(
                                'Driver',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                bookingDetails['vehicleTable']?['vehicleTable']
                                        ?['plate_number'] ??
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

                    const SizedBox(height: 45),

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
                          bookingDetails['seat_type']?.toString() ?? 'Standard',
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
                        Text(
                          bookingDetails['payment_method']?.toString() ??
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

                    const SizedBox(height: 15),
                    // Passenger Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Passenger Count',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212),
                          ),
                        ),
                        Text(
                          bookingDetails['passenger_count']?.toString() ?? '1',
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
                    // Passenger Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Passenger Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212),
                          ),
                        ),
                        Text(
                          bookingDetails['passenger']?['display_name'] ??
                              bookingDetails['passenger_name'] ??
                              'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Map placeholder
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.map,
                          size: 50,
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
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
}
