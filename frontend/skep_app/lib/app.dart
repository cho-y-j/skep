import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_state.dart';
import 'package:skep_app/features/auth/model/user.dart';
import 'package:skep_app/router/app_router.dart';
import 'package:skep_app/core/constants/app_colors.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SKEP',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
      ),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              AppRouter.router.go('/login');
            } else if (state is AuthAuthenticated) {
              // On refresh, AuthStarted restores auth from storage.
              // Navigate to the correct dashboard if currently on login.
              final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
              if (currentLocation == '/login' || currentLocation == '/register' || currentLocation == '/') {
                final role = UserRole.fromString(state.user.role);
                switch (role) {
                  case UserRole.platformAdmin:
                    AppRouter.router.go('/admin-dashboard');
                  case UserRole.equipmentSupplier:
                    AppRouter.router.go('/supplier-dashboard');
                  case UserRole.bpCompany:
                    AppRouter.router.go('/bp-dashboard');
                  case UserRole.driver:
                  case UserRole.guide:
                    AppRouter.router.go('/work-records');
                  case UserRole.safetyInspector:
                    AppRouter.router.go('/inspections/current');
                }
              }
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
