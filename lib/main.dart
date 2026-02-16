import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'injection_container.dart';

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/utils/logger.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Allow all orientations for better responsiveness
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Initialize dependencies
      await initDependencies();

      // Initialize Bloc Observer
      Bloc.observer = AppBlocObserver();

      runApp(App());
    },
    (error, stack) {
      AppLogger.e('Global Exception Caught', error, stack);
    },
  );
}
