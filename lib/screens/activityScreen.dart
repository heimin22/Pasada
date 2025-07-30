import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/widgets/booking_list_item.dart';
import 'package:pasada_passenger_app/screens/viewRideDetailsScreen.dart';
import 'dart:async';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return const ActivityScreenStateful();
  }
}

class ActivityScreenStateful extends StatefulWidget {
  const ActivityScreenStateful({super.key});

  @override
  State<ActivityScreenStateful> createState() => ActivityScreenPageState();
}

class ActivityScreenPageState extends State<ActivityScreenStateful> {
  Timer? _debounceTimer;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), fetchBookings);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchBookings() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in');
        setState(() {
          bookings = [];
          isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('passenger_id', currentUser.id)
          .order('created_at', ascending: false);

      setState(() {
        final allBookings = List<Map<String, dynamic>>.from(response);
        final filteredBookings = allBookings.where((booking) {
          final status = booking['ride_status'] as String?;
          return status != null &&
              (status == 'completed' ||
                  status == 'accepted' ||
                  status == 'ongoing');
        }).toList();
        bookings = filteredBookings.take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      setState(() => isLoading = false);
    }
  }

  void _viewBookingDetails(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewRideDetailsScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Activity',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bookings.isEmpty
                      ? Center(
                          child: Text(
                            'No booking history found',
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            return GestureDetector(
                              onTap: () => _viewBookingDetails(booking),
                              child: BookingListItem(booking: booking),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
