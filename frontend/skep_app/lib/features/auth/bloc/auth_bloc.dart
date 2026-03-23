import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';
import 'package:skep_app/features/auth/bloc/auth_state.dart';
import 'package:skep_app/features/auth/model/user.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DioClient dioClient;

  AuthBloc({required this.dioClient}) : super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
    on<AuthProfileRequested>(_onAuthProfileRequested);
  }

  /// 서버 응답에서 User 객체를 생성하는 헬퍼
  /// 서버는 user 객체를 따로 보내지 않고 flat하게 보냄
  User _parseUserFromResponse(Map<String, dynamic> data) {
    return User(
      id: data['user_id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      companyId: data['company_id'] as String?,
      companyName: data['company_name'] as String?,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    final storage = dioClient.getSecureStorage();
    final token = await storage.getToken();

    if (token == null || token.isEmpty) {
      emit(const AuthUnauthenticated());
      return;
    }

    // 저장된 정보로 바로 인증 상태 복원
    final userId = await storage.getUserId();
    final email = await storage.getUserEmail();
    final role = await storage.getUserRole();

    if (userId != null && email != null && role != null) {
      final user = User(
        id: userId,
        email: email,
        name: email.split('@').first,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
      );
      emit(AuthAuthenticated(user: user, token: token));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': event.email,
          'password': event.password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final token = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (token != null) {
          final user = _parseUserFromResponse(data);
          final storage = dioClient.getSecureStorage();

          await storage.saveToken(token);
          if (refreshToken != null) {
            await storage.saveRefreshToken(refreshToken);
          }
          await storage.saveUserId(user.id);
          await storage.saveUserEmail(user.email);
          await storage.saveUserRole(user.role);
          if (user.companyId != null) {
            await storage.saveCompanyId(user.companyId!);
          }

          emit(AuthAuthenticated(user: user, token: token));
          return;
        }
      }

      emit(const AuthFailure(message: '로그인에 실패했습니다'));
    } catch (error) {
      emit(AuthFailure(message: '로그인 실패: $error'));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final data = <String, dynamic>{
        'email': event.email,
        'password': event.password,
        'name': event.name,
        'role': event.role,
        'phone': event.phone ?? '010-0000-0000',
      };

      if (event.companyName != null) {
        data['companyName'] = event.companyName!;
      }
      if (event.companyType != null) {
        data['companyType'] = event.companyType!;
      }
      if (event.businessNumber != null) {
        data['businessNumber'] = event.businessNumber!;
      }
      if (event.representative != null) {
        data['representative'] = event.representative!;
      }
      if (event.address != null) {
        data['address'] = event.address!;
      }
      if (event.companyPhone != null) {
        data['companyPhone'] = event.companyPhone!;
      }

      final response = await dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: data,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        // For company registration, navigate to login instead of auto-login
        final isCompanyRegistration = event.companyName != null &&
            event.companyName!.isNotEmpty;

        if (isCompanyRegistration) {
          emit(const AuthRegisterSuccess());
          return;
        }

        // For individual registration, auto-login as before
        final responseData = response.data!;
        final token = responseData['access_token'] as String?;
        final refreshToken = responseData['refresh_token'] as String?;

        if (token != null) {
          final user = _parseUserFromResponse(responseData);
          final storage = dioClient.getSecureStorage();

          await storage.saveToken(token);
          if (refreshToken != null) {
            await storage.saveRefreshToken(refreshToken);
          }
          await storage.saveUserId(user.id);
          await storage.saveUserEmail(user.email);
          await storage.saveUserRole(user.role);

          emit(AuthAuthenticated(user: user, token: token));
          return;
        }
      }

      emit(const AuthFailure(message: '회원가입에 실패했습니다'));
    } catch (error) {
      emit(AuthFailure(message: '회원가입 실패: $error'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final storage = dioClient.getSecureStorage();
      await storage.clearAll();
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final storage = dioClient.getSecureStorage();
      final refreshToken = await storage.getRefreshToken();

      if (refreshToken == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      final response = await dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final newToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newToken != null) {
          await storage.saveToken(newToken);
          if (newRefreshToken != null) {
            await storage.saveRefreshToken(newRefreshToken);
          }
          add(const AuthProfileRequested());
          return;
        }
      }

      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthProfileRequested(
    AuthProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final storage = dioClient.getSecureStorage();
      final token = await storage.getToken();
      final userId = await storage.getUserId();
      final email = await storage.getUserEmail();
      final role = await storage.getUserRole();

      if (token != null && userId != null && email != null && role != null) {
        final user = User(
          id: userId,
          email: email,
          name: email.split('@').first,
          role: role,
          isActive: true,
          createdAt: DateTime.now(),
        );
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (error) {
      emit(const AuthUnauthenticated());
    }
  }
}
