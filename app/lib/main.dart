import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/intro.dart';
import 'screens/shell.dart';
import 'services/notifications.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  final state = AppState();
  await state.load();
  await Notifications.instance.init();
  Notifications.instance.reschedule(state);
  runApp(LeaFioreApp(state: state));
}

class LeaFioreApp extends StatelessWidget {
  final AppState state;
  const LeaFioreApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'LeaFiore',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: state.onboarded ? const Shell() : const IntroScreen(),
      ),
    );
  }
}
