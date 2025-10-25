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

    // Calculate responsive values following the pattern from other dialogs
    final iconSize = screenSize.width * 0.12; // 12% of screen width
    final titleFontSize = screenSize.width * 0.045; // 4.5% of screen width
    final descriptionFontSize =
        screenSize.width * 0.035; // 3.5% of screen width
    final buttonFontSize = 12.0; // Fixed 12px as requested
    final padding = screenSize.width * 0.05; // 5% of screen width
    final spacing = screenSize.height * 0.015; // 1.5% of screen height
    final buttonHeight = screenSize.height * 0.045; // 4.5% of screen height

    return Dialog(
      backgroundColor:
          isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.025),
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.08,
        vertical: screenSize.height * 0.1,
      ),
      child: Container(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: iconSize * 0.6,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: spacing),

            // Title
            Text(
              'Capacity Limit Reached',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 0.8),

            // Description
            Text(
              'Boss, puno na yung ${currentSeatType.toLowerCase()} capacity. Gusto mo bang palitan ng ${alternativeSeatType.toLowerCase()}?',
              style: TextStyle(
                fontSize: descriptionFontSize,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 1.5),

            // Action Buttons
            Row(
              children: [
                // Decline Button
                Expanded(
                  child: Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                        width: 1.5,
                      ),
                      borderRadius:
                          BorderRadius.circular(screenSize.width * 0.015),
                    ),
                    child: TextButton(
                      onPressed: onDecline,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenSize.width * 0.015),
                        ),
                      ),
                      child: Text(
                        'Find Another Driver',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenSize.width * 0.025),

                // Accept Button
                Expanded(
                  child: Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00CC58), Color(0xFF00A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(screenSize.width * 0.015),
                    ),
                    child: TextButton(
                      onPressed: onAccept,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenSize.width * 0.015),
                        ),
                      ),
                      child: Text(
                        'Change to $alternativeSeatType',
                        style: TextStyle(
                          fontSize: buttonFontSize,
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
