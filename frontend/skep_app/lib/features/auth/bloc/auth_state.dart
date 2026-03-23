import 'package:equatable/equatable.dart';
import 'package:skep_app/features/auth/model/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;
  final dynamic error;

  const AuthFailure({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

class AuthRegisterSuccess extends AuthState {
  final String message;

  const AuthRegisterSuccess({
    this.message = '가입이 완료되었습니다. 로그인해주세요.',
  });

  @override
  List<Object?> get props => [message];
}

class AuthProfileLoaded extends AuthState {
  final User user;

  const AuthProfileLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}
