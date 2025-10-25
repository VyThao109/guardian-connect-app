import 'package:flutter/material.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';

class DualActionButtons extends StatelessWidget {
  final String label1;
  final String label2;
  final IconData icon1;
  final IconData icon2;
  final VoidCallback onPressed1;
  final VoidCallback onPressed2;

  const DualActionButtons({
    super.key,
    required this.label1,
    required this.label2,
    required this.icon1,
    required this.icon2,
    required this.onPressed1,
    required this.onPressed2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 20,
      children: [
        // Button 1
        Expanded(
          child: TextButton.icon(
            onPressed: onPressed1,
            icon: Icon(icon1, size: 20),
            label: Text(label1),
            style: TextButton.styleFrom(
              backgroundColor: context.theme.blue300,
              foregroundColor: context.theme.blue,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: context.theme.blue500 ?? Colors.lightBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Button 2
        Expanded(
          child: TextButton.icon(
            onPressed: onPressed2,
            icon: Icon(icon2, size: 20),
            label: Text(label2),
            style: TextButton.styleFrom(
              backgroundColor: label2 == "Emergency call"
                  ? context.theme.red
                  : context.theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
