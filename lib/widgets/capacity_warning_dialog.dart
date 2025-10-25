import 'package:flutter/material.dart';

class CapacityWarningDialog extends StatelessWidget {
  final String currentSeatType;
  final String alternativeSeatType;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const CapacityWarningDialog({
    super.key,
    required this.currentSeatType,
    required this.alternativeSeatType,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor:
          isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: screenSize.height * 0.03,
      ),
      child: Container(
        padding: EdgeInsets.all(screenSize.width * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              width: screenSize.width * 0.15,
              height: screenSize.width * 0.15,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: screenSize.width * 0.08,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Title
            Text(
              'Capacity Limit Reached',
              style: TextStyle(
                fontSize: screenSize.width * 0.055,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenSize.height * 0.015),

            // Description
            Text(
              'The vehicle has reached its ${currentSeatType.toLowerCase()} capacity. Would you like to change to ${alternativeSeatType.toLowerCase()} instead?',
              style: TextStyle(
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenSize.height * 0.025),

            // Action Buttons
            Row(
              children: [
                // Decline Button
                Expanded(
                  child: Container(
                    height: screenSize.height * 0.055,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                        width: 1.5,
                      ),
                      borderRadius:
                          BorderRadius.circular(screenSize.width * 0.02),
                    ),
                    child: TextButton(
                      onPressed: onDecline,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenSize.width * 0.02),
                        ),
                      ),
                      child: Text(
                        'Find Another Driver',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.04,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenSize.width * 0.03),

                // Accept Button
                Expanded(
                  child: Container(
                    height: screenSize.height * 0.055,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00CC58), Color(0xFF00A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(screenSize.width * 0.02),
                    ),
                    child: TextButton(
                      onPressed: onAccept,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenSize.width * 0.02),
                        ),
                      ),
                      child: Text(
                        'Change to $alternativeSeatType',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.04,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String currentSeatType,
    required String alternativeSeatType,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CapacityWarningDialog(
        currentSeatType: currentSeatType,
        alternativeSeatType: alternativeSeatType,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }
}
