import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:flutter_svg/flutter_svg.dart';

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

    return Column(
      children: [
        ListTile(
          onTap: press,
          horizontalTitleGap: 0,
          contentPadding: const EdgeInsets.only(left: 16, right: 16),
          leading: SvgPicture.asset(
            "assets/svg/locationPin.svg",
            width: 14,
            height: 14,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                landmark,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: Color(0xFF121212),
                ),
              ),
              if (address.isNotEmpty) ...[
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                    color: Color(0xFF666666),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
