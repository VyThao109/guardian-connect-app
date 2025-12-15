import 'package:flutter/material.dart';
import 'package:guardian_connect_app/presentations/screens/root_screen.dart';
import 'package:guardian_connect_app/presentations/screens/setting_screen.dart';

class Routes {
  static const root = "/";
  static const setting = "/setting";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return MaterialPageRoute(builder: (context) => const RootScreen());
      case setting:
        return MaterialPageRoute(builder: (context) => const SettingScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('No page route provided')),
          ),
        );
    }
  }
}
