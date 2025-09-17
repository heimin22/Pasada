import 'package:flutter/material.dart';

class HolidayBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;

  const HolidayBanner({super.key, required this.message, this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF00CC58), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF5F5F5),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClose != null)
              IconButton(
                icon:
                    const Icon(Icons.close, size: 16, color: Color(0xFFCCCCCC)),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              )
          ],
        ),
      ),
    );
  }
}
