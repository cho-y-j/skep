import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_state.dart';
import 'package:skep_app/features/auth/model/user.dart';
import 'package:skep_app/features/auth/view/login_screen.dart';
import 'package:skep_app/features/auth/view/register_screen.dart';
import 'package:skep_app/features/dashboard/view/admin_dashboard.dart';
import 'package:skep_app/features/dashboard/view/bp_dashboard.dart';
import 'package:skep_app/features/dashboard/view/supplier_dashboard.dart';
import 'package:skep_app/features/dashboard/view/worker_dashboard.dart';
import 'package:skep_app/features/dispatch/bloc/dispatch_bloc.dart';
import 'package:skep_app/features/dispatch/view/work_record_screen.dart';
import 'package:skep_app/features/inspection/bloc/inspection_bloc.dart';
import 'package:skep_app/features/inspection/view/safety_inspection_screen.dart';
import 'package:skep_app/features/location/bloc/location_bloc.dart';
import 'package:skep_app/features/location/view/location_map_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;

      // While auth is still initializing (e.g. on page refresh),
      // don't redirect - let the BlocListener in App handle navigation
      // once AuthStarted finishes restoring from SecureStorage.
      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (authState is AuthAuthenticated) {
        if (state.matchedLocation == '/login' ||
            state.matchedLocation == '/register') {
          return _getInitialRouteByRole(authState.user.role);
        }
      } else {
        if (state.matchedLocation != '/login' &&
            state.matchedLocation != '/register') {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Dashboard routes
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/supplier-dashboard',
        builder: (context, state) => const SupplierDashboard(),
      ),
      GoRoute(
        path: '/bp-dashboard',
        builder: (context, state) => const BPDashboard(),
      ),

      // Worker dashboard (DRIVER, GUIDE, SAFETY_INSPECTOR)
      GoRoute(
        path: '/worker-dashboard',
        builder: (context, state) => const WorkerDashboard(),
      ),

      // Work Record routes (legacy)
      GoRoute(
        path: '/work-records',
        builder: (context, state) => BlocProvider(
          create: (context) => DispatchBloc(
            dioClient: context.read<DioClient>(),
          ),
          child: const WorkRecordScreen(),
        ),
      ),

      // Inspection routes
      GoRoute(
        path: '/inspections/:inspectionId',
        builder: (context, state) {
          final inspectionId = state.pathParameters['inspectionId'] ?? '';
          return BlocProvider(
            create: (context) => InspectionBloc(
              dioClient: context.read<DioClient>(),
            ),
            child: SafetyInspectionScreen(
              inspectionId: inspectionId,
            ),
          );
        },
      ),

      // Location map route
      GoRoute(
        path: '/locations',
        builder: (context, state) => BlocProvider(
          create: (context) => LocationBloc(
            dioClient: context.read<DioClient>(),
          ),
          child: const LocationMapScreen(),
        ),
      ),

      // Placeholder routes for other features
      GoRoute(
        path: '/equipments',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Equipment List - Coming Soon'),
          ),
        ),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Documents - Coming Soon'),
          ),
        ),
      ),
      GoRoute(
        path: '/deployments',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Deployments - Coming Soon'),
          ),
        ),
      ),
      GoRoute(
        path: '/settlements',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Settlements - Coming Soon'),
          ),
        ),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Statistics - Coming Soon'),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );

  static String _getInitialRouteByRole(String role) {
    final userRole = UserRole.fromString(role);
    switch (userRole) {
      case UserRole.platformAdmin:
        return '/admin-dashboard';
      case UserRole.equipmentSupplier:
        return '/supplier-dashboard';
      case UserRole.bpCompany:
        return '/bp-dashboard';
      case UserRole.driver:
      case UserRole.guide:
      case UserRole.safetyInspector:
        return '/worker-dashboard';
    }
  }
}
