import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/core/services/sos_notification_service.dart';
import 'package:guardian_connect_app/presentations/widgets/button/common_button.dart';
import 'package:guardian_connect_app/presentations/widgets/container/quick_actions.dart';

class AlertTab extends StatefulWidget {
  const AlertTab({super.key});

  @override
  State<AlertTab> createState() => _AlertTabState();
}

class _AlertTabState extends State<AlertTab> with TickerProviderStateMixin {
  late SOSNotificationService _sosService;

  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _sosService = RepositoryProvider.of<SOSNotificationService>(context);

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
    _sosService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootBloc, RootState>(
      buildWhen: (previous, current) {
        return previous.isSOS != current.isSOS ||
            previous.isSosNotificationEnabled !=
                current.isSosNotificationEnabled ||
            previous.isConnected != current.isConnected;
      },
      builder: (context, state) {
        final bool isEnable =
            state.isSosNotificationEnabled && state.isConnected;
        final bool isSOSEnable = state.isSosNotificationEnabled;
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
                              'Cảnh báo khẩn cấn SOS',
                              style: TextStyle(
                                fontSize: FontSizes.large,
                                fontWeight: FontWeight.w700,
                                color: context.theme.black,
                              ),
                            ),
                            Text(
                              'Nhận tín hiệu khẩn cấp từ người thân',
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
                            horizontal: 8,
                            vertical: 4,
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
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isEnable
                                      ? context.theme.green
                                      : isSOSEnable
                                      ? Colors.orange
                                      : context.theme.grayBgColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                isEnable
                                    ? "Sẵn sàng"
                                    : isSOSEnable
                                    ? "Bật"
                                    : "Tắt",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: FontSizes.small,
                                  fontWeight: FontWeight.w500,
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
                            child: CommonButton(
                              label: "Tắt cảnh báo",
                              icon: Feather.refresh_cw,
                              onPressed: () {
                                context.read<RootBloc>().add(
                                  ClearEmergencyEvent(),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              QuickActionsContainer(),
            ],
          ),
        );
      },
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
                  color: (context.theme.red ?? Colors.redAccent).withAlpha(60),
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
                  "Tình trạng khẩn cấp",
                  style: TextStyle(
                    fontSize: FontSizes.small,
                    fontWeight: FontWeight.normal,
                    color: context.theme.grayTextColor,
                  ),
                ),
                Text(
                  sosState ? "Nguy hiểm" : "Bình thường",
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
