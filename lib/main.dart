import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/routes/routes.dart';
import 'package:guardian_connect_app/core/data/local_storage.dart';
import 'package:guardian_connect_app/core/services/sos_notification_service.dart';
import 'package:guardian_connect_app/core/services/web_rtc_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.setup();

  final sosService = SOSNotificationService();
  await sosService.initialize();

  final webrtcService = WebRTCService();

  runApp(
    MyApp(
      navigatorKey: navigatorKey,
      sosService: sosService,
      webrtcService: webrtcService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final SOSNotificationService sosService;
  final WebRTCService webrtcService;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.sosService,
    required this.webrtcService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: sosService),
        RepositoryProvider.value(value: webrtcService),
      ],
      child: BlocProvider(
        create: (context) =>
            RootBloc(webrtcService: webrtcService, sosService: sosService)
              ..add(const InitializeAppEvent()),
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
      ),
    );
  }
}
