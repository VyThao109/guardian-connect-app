import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';

class CustomNavigator extends StatelessWidget {
  const CustomNavigator({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final Function(int) onTap;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.theme.grayBgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // 🟦 Animated white background moves under selected item
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: _getAlignment(selectedIndex),
            child: Container(
              width:
                  MediaQuery.of(context).size.width / 3 * 0.85, // chia 3 item
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildNavItem(
                iconURL:
                    "assets/icons/material-symbols_home-outline-rounded.svg",
                label: 'Home',
                index: 0,
                context: context,
              ),
              buildNavItem(
                iconURL: "assets/icons/mingcute_location-line.svg",
                label: 'Location',
                index: 1,
                context: context,
              ),
              buildNavItem(
                iconURL: "assets/icons/noti-vector.svg",
                label: 'Alert',
                index: 2,
                context: context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Alignment _getAlignment(int index) {
    switch (index) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.center;
      case 2:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  Widget buildNavItem({
    required String iconURL,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          height: 32,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
            children: [
              SvgPicture.asset(
                iconURL,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  context.theme.black ?? Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: context.theme.black,
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
