import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';
import 'routing/app_router.dart';

/// Main App Widget
class App extends StatelessWidget {
  App({super.key});

  late final _appRouter = AppRouter(authBloc: sl<AuthBloc>());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>())],
      child: MaterialApp.router(
        title: 'EDU Learning Platform',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
