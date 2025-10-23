import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/routes/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  runApp(MyApp(navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp(this.navigatorKey, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: context.theme.primaryColor ?? Colors.blue,
        ),
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),
      onGenerateRoute: Routes.onGenerateRoute,
      initialRoute: Routes.root,
    );
  }
}
