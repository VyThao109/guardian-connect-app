import 'package:flutter/material.dart';
import 'package:guardian_connect_app/presentations/screens/root_screen.dart';

class Routes {
  static const root = "/";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return MaterialPageRoute(builder: (context) => const RootScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('No page route provided')),
          ),
        );
    }
  }
}
