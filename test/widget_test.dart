// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pasada_passenger_app/widgets/booking_list_item.dart'; // Import your widget

void main() {
  testWidgets('Preview BookingListItem widget', (WidgetTester tester) async {
    // Sample booking data
    final booking = {
      'pickup_address': '123 Main St',
      'dropoff_address': '456 Market St',
      'created_at': DateTime.now().toIso8601String(),
      'fare': 150.00,
    };

    // Build our widget and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BookingListItem(
              booking: booking,
            ),
          ),
        ),
      ),
    );

    // Verify the widget's appearance
    expect(find.text('123 Main St to 456 Market St'), findsOneWidget);
    // You can add expectations to verify the widget's appearance
    // For example:
    // expect(find.text('Booking #123'), findsOneWidget);
    // expect(find.text('Pending'), findsOneWidget);
  });
}
