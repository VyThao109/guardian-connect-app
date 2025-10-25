import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/routes/routes.dart';
import 'package:guardian_connect_app/core/data/local_storage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.setup();
  runApp(MyApp(navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp(this.navigatorKey, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RootBloc()..add(const InitializeAppEvent()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          fontFamily: GoogleFonts.inter().fontFamily,
          extensions: [CustomThemeExtension.lightMode],
          colorScheme: ColorScheme.fromSeed(
            seedColor:
                CustomThemeExtension.lightMode.primaryColor ?? Colors.blue,
          ),
          textTheme: Theme.of(
            context,
          ).textTheme.apply(fontSizeFactor: 1, fontSizeDelta: 0.0),
          scaffoldBackgroundColor: Colors.white,
        ),
        onGenerateRoute: Routes.onGenerateRoute,
        initialRoute: Routes.root,
      ),
    );
  }
}
