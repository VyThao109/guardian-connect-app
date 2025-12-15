import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    this.activeIcon = Icons.notifications_active,
    this.inactiveIcon = Icons.notifications_off,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 60,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          // Đổi màu nền: Xanh khi bật, Xám khi tắt
          color: value ? activeColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Stack(
          children: [
            // Nút tròn trắng (Thumb) di chuyển
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      value ? activeIcon : inactiveIcon,
                      key: ValueKey<bool>(value),
                      size: 16,
                      color: value ? activeColor : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
