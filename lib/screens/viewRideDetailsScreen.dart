import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ViewRideDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;

  const ViewRideDetailsScreen({super.key, this.booking});

  @override
  State<ViewRideDetailsScreen> createState() => _ViewRideDetailsScreenState();
}

class _ViewRideDetailsScreenState extends State<ViewRideDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic> bookingDetails = {};

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      bookingDetails = widget.booking!;
      isLoading = false;
    } else {
      // Fetch booking details if not provided
      fetchBookingDetails();
    }
  }

  Future<void> fetchBookingDetails() async {
    // This would be implemented to fetch booking details if needed
    setState(() => isLoading = false);
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ride Receipt',
          style: TextStyle(
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Implement contact support functionality
            },
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
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              bookingDetails['id']?.toString() ?? 'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () => _copyToClipboard(
                                  bookingDetails['id']?.toString() ?? ''),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Driver Profile Placeholder
                    Center(
                      child: Column(
                        children: [
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
                          const SizedBox(height: 10),
                          Text(
                            bookingDetails['driver_name'] ?? 'Driver Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                          Text(
                            bookingDetails['vehicle_details'] ??
                                'Vehicle Details',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ),
                          Text(
                            bookingDetails['plate_number'] ?? 'Plate Number',
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

                    const SizedBox(height: 20),

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
                          '₱${bookingDetails['fare'] ?? '0.00'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

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
                          bookingDetails['passenger_name'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 10),

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
                                bookingDetails['pickup_location'] ??
                                    'Pickup Location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                bookingDetails['dropoff_location'] ??
                                    'Dropoff Location',
                                style: TextStyle(
                                  fontSize: 14,
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
        padding: const EdgeInsets.all(16.0),
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
              borderRadius: BorderRadius.circular(10),
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
