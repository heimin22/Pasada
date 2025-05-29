import 'package:flutter/material.dart';

Future<String?> showSeatingPreferenceBottomSheet(
    BuildContext context, String currentSelection) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SeatingPreferenceSheetContent(
      currentSelection: currentSelection,
    ),
  );
}

class SeatingPreferenceSheetContent extends StatefulWidget {
  final String currentSelection;
  const SeatingPreferenceSheetContent(
      {super.key, required this.currentSelection});

  @override
  _SeatingPreferenceSheetContentState createState() =>
      _SeatingPreferenceSheetContentState();
}

class _SeatingPreferenceSheetContentState
    extends State<SeatingPreferenceSheetContent> {
  late String tempSelection;

  @override
  void initState() {
    super.initState();
    tempSelection = widget.currentSelection;
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String value,
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required Color selectedColor,
    required Color unselectedBorderColor,
    required Color unselectedIconColor,
    required Color unselectedTextColor,
  }) {
    final bool isSelected = tempSelection == value;

    Color effectiveCardColor;
    if (isSelected) {
      effectiveCardColor = isDarkMode
          // Original selectedColor (0xFF00D65C) with 25% opacity for dark mode
          ? const Color(0x4000D65C)
          // Original Colors.green.shade600 (0xFF388E3C) with 15% opacity for light mode
          : const Color(0x26388E3C);
    } else {
      effectiveCardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    }

    return GestureDetector(
      onTap: () => setState(() => tempSelection = value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: effectiveCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : unselectedBorderColor,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: isSelected && !isDarkMode
              ? [
                  BoxShadow(
                    color: isDarkMode
                        ? const Color(0x4000D65C).withAlpha(50)
                        : const Color(0x26388E3C).withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedIconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : unselectedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDarkMode ? const Color(0xFF00D65C) : Colors.green.shade600;
    final unselectedBorderColor =
        isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final unselectedIconColor =
        isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final unselectedTextColor =
        isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final sheetBackgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7);

    return Container(
      decoration: BoxDecoration(
        color: sheetBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Seating Preference',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 18),
            _buildOptionCard(
              context: context,
              value: 'Sitting',
              title: 'Sitting',
              icon: Icons.event_seat_outlined,
              isDarkMode: isDarkMode,
              selectedColor: selectedColor,
              unselectedBorderColor: unselectedBorderColor,
              unselectedIconColor: unselectedIconColor,
              unselectedTextColor: unselectedTextColor,
            ),
            _buildOptionCard(
              context: context,
              value: 'Standing',
              title: 'Standing',
              icon: Icons.directions_walk,
              isDarkMode: isDarkMode,
              selectedColor: selectedColor,
              unselectedBorderColor: unselectedBorderColor,
              unselectedIconColor: unselectedIconColor,
              unselectedTextColor: unselectedTextColor,
            ),
            _buildOptionCard(
              context: context,
              value: 'Any',
              title: 'Any',
              icon: Icons.all_inclusive_outlined,
              isDarkMode: isDarkMode,
              selectedColor: selectedColor,
              unselectedBorderColor: unselectedBorderColor,
              unselectedIconColor: unselectedIconColor,
              unselectedTextColor: unselectedTextColor,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(tempSelection),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedColor,
                      foregroundColor:
                          isDarkMode ? Colors.black87 : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: isDarkMode ? 2 : 4,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
}
