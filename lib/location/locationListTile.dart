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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ListTile(
              onTap: press,
              horizontalTitleGap: 0,
              leading: SvgPicture.asset(
                "assets/svg/locationPin.svg",
                width: 24,
                height: 24,
              ),
              title: Text(
                location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(
              height: 2,
              thickness: 2,
              color: Color(0xFFE9E9E9),
            )
          ],
        )
      ],
    );
  }
}
