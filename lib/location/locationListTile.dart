import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LocationListTile extends StatelessWidget {
  const LocationListTile({
    super.key,
    required this.location,
    required this.press,
  });

  final String location;
  final VoidCallback press;

  // helper method para masplit yung location into landmark and address
  List<String> splitLocation(String location) {
    final List<String> parts = location.split(',');
    if (parts.length < 2) return [location, ''];
    return [parts[0], parts.sublist(1).join(', ')];
  }

  @override
  Widget build(BuildContext context) {
    final parts = splitLocation(location);
    final landmark = parts[0];
    final address = parts[1];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        ListTile(
          onTap: press,
          horizontalTitleGap: 0,
          contentPadding: const EdgeInsets.only(left: 16, right: 16),
          title: Row(
            children: [
              SvgPicture.asset(
                "assets/svg/pindropoff.svg",
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      landmark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                          color: isDarkMode
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
