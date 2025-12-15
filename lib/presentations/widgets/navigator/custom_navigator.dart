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
    const double indicatorWidth = 40.0;

    return Container(
      height: 60 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // SLIDING INDICATOR
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
            alignment: Alignment((selectedIndex - 1).toDouble(), -1.0),

            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1.0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: indicatorWidth,
                  height: 2,
                  decoration: BoxDecoration(
                    color: context.theme.primaryColor ?? Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  label: "Trang chủ",
                  iconPath:
                      "assets/icons/material-symbols_home-outline-rounded.svg",
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  label: "Định vị",
                  iconPath: "assets/icons/mingcute_location-line.svg",
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  label: "Cảnh báo",
                  iconPath: "assets/icons/noti-vector.svg",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required String iconPath,
  }) {
    final isSelected = index == selectedIndex;
    final primaryColor = context.theme.primaryColor ?? Colors.blue;
    final iconColor = isSelected ? primaryColor : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: primaryColor.withAlpha(50),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: FontSizes.small - 2,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
