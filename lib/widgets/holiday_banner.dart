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
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E3B4E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFCE21), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFFFCE21)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF5F5F5),
                ),
              ),
            ),
            if (onClose != null)
              IconButton(
                icon:
                    const Icon(Icons.close, size: 18, color: Color(0xFFF5F5F5)),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
          ],
        ),
      ),
    );
  }
}
