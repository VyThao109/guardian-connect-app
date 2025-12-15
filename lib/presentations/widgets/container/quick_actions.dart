import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/presentations/widgets/button/dual_action_buttons.dart';
import 'package:guardian_connect_app/utils/functions.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickActionsContainer extends StatelessWidget {
  const QuickActionsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          "Tác vụ nhanh",
          style: TextStyle(
            color: context.theme.black,
            fontSize: FontSizes.large,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.left,
        ),
        DualActionButtons(
          label1: "Gọi người thân",
          label2: "Gọi cấp cứu",
          icon1: Ionicons.call_outline,
          icon2: AntDesign.warning,
          onPressed1: () {
            FunctionsHelper.showContactModal(context);
          },
          onPressed2: () async {
            await launchUrl(
              Uri(scheme: 'tel', path: "115"),
              mode: LaunchMode.externalApplication,
            );
          },
          isBtn2Emergency: true,
        ),
      ],
    );
  }
}
