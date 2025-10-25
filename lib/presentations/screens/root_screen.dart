import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/presentations/widgets/navigator/custom_navigator.dart';
import 'package:guardian_connect_app/presentations/widgets/root_tab/alert_tab.dart';
import 'package:guardian_connect_app/presentations/widgets/root_tab/home_tab.dart';
import 'package:guardian_connect_app/presentations/widgets/root_tab/location_tab.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final List<Widget> _screens = [
    const HomeTab(),
    const LocationTab(),
    const AlertTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootBloc, RootState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.theme.primaryColor,
            elevation: 0,
            toolbarHeight: 80,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                spacing: 4,
                children: [
                  Text(
                    'Guardian Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: FontSizes.extraLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stay connected with your loved one',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: FontSizes.small,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                spacing: 24,
                children: [
                  CustomNavigator(
                    selectedIndex: state.selectedTabIndex,
                    onTap: (index) =>
                        context.read<RootBloc>().add(ChangeTabEvent(index)),
                  ),
                  _screens[state.selectedTabIndex],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
