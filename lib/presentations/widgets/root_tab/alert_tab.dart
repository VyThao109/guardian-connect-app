import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/utils/functions.dart';
import 'package:guardian_connect_app/presentations/widgets/button/dual_action_buttons.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertTab extends StatefulWidget {
  const AlertTab({super.key});

  @override
  State<AlertTab> createState() => _AlertTabState();
}

class _AlertTabState extends State<AlertTab> with TickerProviderStateMixin {
  bool isEnable = false;

  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation rung lắc
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation =
        Tween<double>(
            begin: 0,
            end: 10,
          ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _shakeController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) _shakeController.forward();
              });
            }
          });

    // Animation pulse (phóng to thu nhỏ)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootBloc, RootState>(
      buildWhen: (previous, current) {
        return previous.isSOS != current.isSOS;
      },
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            spacing: 24,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.theme.grayBgColor ?? Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  spacing: 20,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              'Emergency SOS',
                              style: TextStyle(
                                fontSize: FontSizes.large,
                                fontWeight: FontWeight.w700,
                                color: context.theme.black,
                              ),
                            ),
                            Text(
                              'Emergency alert system',
                              style: TextStyle(
                                fontSize: FontSizes.small,
                                fontWeight: FontWeight.normal,
                                color: context.theme.grayTextColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            spacing: 4,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isEnable
                                      ? context.theme.green
                                      : context.theme.grayBgColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                isEnable ? "Enable" : "Disable",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: FontSizes.small,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      spacing: 12,
                      children: [
                        buildAlertStatusContainer(context, state),
                        if (state.isSOS)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<RootBloc>().add(
                                  ClearEmergencyEvent(),
                                );
                              },
                              icon: Icon(MaterialCommunityIcons.refresh),
                              label: Text("Reset alert"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              buildActionBtnsSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget buildActionBtnsSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            color: context.theme.black,
            fontSize: FontSizes.large,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.left,
        ),
        DualActionButtons(
          label1: "Reach companion",
          label2: "Emergency call",
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
        ),
      ],
    );
  }

  Widget buildAlertStatusContainer(BuildContext context, RootState state) {
    final sosState = state.isSOS;

    // Bắt đầu animation khi SOS
    if (sosState && !_shakeController.isAnimating) {
      _shakeController.forward();
    } else if (!sosState) {
      _shakeController.stop();
      _shakeController.reset();
    }

    Widget container = Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sosState
              ? context.theme.red500 ?? Colors.redAccent
              : context.theme.blue500 ?? Colors.blueAccent,
          width: sosState ? 2 : 1,
        ),
        color: sosState ? context.theme.red300 : context.theme.blue300,
        // Thêm shadow khi SOS
        boxShadow: sosState
            ? [
                BoxShadow(
                  color: (context.theme.red ?? Colors.redAccent).withOpacity(
                    0.5,
                  ),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(
              sosState
                  ? Ionicons.warning_outline
                  : Ionicons.notifications_outline,
              color: sosState
                  ? context.theme.red ?? Colors.redAccent
                  : context.theme.blue ?? Colors.blueAccent,
              size: 60,
            ),
            Column(
              spacing: 2,
              children: [
                Text(
                  "Alert status",
                  style: TextStyle(
                    fontSize: FontSizes.small,
                    fontWeight: FontWeight.normal,
                    color: context.theme.grayTextColor,
                  ),
                ),
                Text(
                  sosState ? "Emergency" : "Normal",
                  style: TextStyle(
                    color: sosState
                        ? context.theme.red ?? Colors.redAccent
                        : context.theme.blue ?? Colors.blueAccent,
                    fontSize: FontSizes.large,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!sosState) return container;

    // Áp dụng cả shake và pulse khi SOS
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _pulseController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * (1 - (_shakeController.value * 2).abs()),
            0,
          ),
          child: Transform.scale(scale: _pulseAnimation.value, child: child),
        );
      },
      child: container,
    );
  }
}
