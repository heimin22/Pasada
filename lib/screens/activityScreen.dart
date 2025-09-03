import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/widgets/booking_list_item.dart';
import 'package:pasada_passenger_app/screens/viewRideDetailsScreen.dart';
import 'dart:async';
import 'package:pasada_passenger_app/screens/offflineConnectionCheckService.dart';

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
  bool isSynced = true;

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
      setState(() {
        // mark as syncing; UI may show indicator accordingly
        isSynced = false;
      });
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in');
        setState(() {
          bookings = [];
          isLoading = false;
          isSynced = true;
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
        isSynced = true;
      });
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      setState(() {
        isLoading = false;
        isSynced = false;
      });
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
    final connectivityService = OfflineConnectionCheckService();

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
            // Not synced / offline indicator
            StreamBuilder<bool>(
              stream: connectivityService.connectionStream,
              initialData: connectivityService.isConnected,
              builder: (context, snapshot) {
                final online = snapshot.data ?? true;
                final showBanner = !online || !isSynced;
                if (!showBanner) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  color: const Color(0x33D7481D),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_problem, color: Color(0xFFD7481D), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          online ? 'Data may be out of date. Pull to refresh.' : 'Offline. Showing last known data.',
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchBookings,
                color: const Color(0xFF067837),
                child: isLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : bookings.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'No booking history found',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? const Color(0xFFF5F5F5)
                                        : const Color(0xFF121212),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          ],
        ),
      ),
    );
  }
}
