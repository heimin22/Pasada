import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';

Future<bool?> showAppBookingConfirmationDialog({
  required BuildContext context,
}) async {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = const Color(0xFF00CC58); // App's primary green

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => ResponsiveDialog(
      title: 'Confirm Your Booking',
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please review your pickup, drop-off, and fare details. Are you sure you want to proceed?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: isDarkMode
                  ? const Color(0xFFDEDEDE)
                  : const Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        ElevatedButton(
          // Cancel
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: primaryColor, width: 3),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(150, 40),
            backgroundColor: Colors.transparent,
            foregroundColor:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Cancel',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 15)),
        ),
        ElevatedButton(
          // Confirm
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(150, 40),
            backgroundColor: primaryColor,
            foregroundColor: Color(0xFFF5F5F5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Confirm',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 15)),
        ),
      ],
    ),
  );
}
