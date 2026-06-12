import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? bloodType;
  final String? gender;
  final String? phone;
  const AuthRegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
    this.bloodType,
    this.gender,
    this.phone,
  });
  @override
  List<Object?> get props => [fullName, email, password, bloodType];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthProfileUpdated extends AuthEvent {}
