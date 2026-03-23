import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role;
  final String? companyName;
  final String? companyType;
  final String? phone;
  final String? businessNumber;
  final String? representative;
  final String? address;
  final String? companyPhone;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.companyName,
    this.companyType,
    this.phone,
    this.businessNumber,
    this.representative,
    this.address,
    this.companyPhone,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        role,
        companyName,
        companyType,
        phone,
        businessNumber,
        representative,
        address,
        companyPhone,
      ];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

class AuthProfileRequested extends AuthEvent {
  const AuthProfileRequested();
}
