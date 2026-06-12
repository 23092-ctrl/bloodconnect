import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../../../core/storage/local_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDataSource _dataSource;

  AuthBloc(this._dataSource) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdated>(_onProfileUpdated);
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    if (!LocalStorage.isAuthenticated) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      final user = await _dataSource.getProfile();
      emit(AuthAuthenticated(user));
    } catch (_) {
      await LocalStorage.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _dataSource.login(
        email: event.email,
        password: event.password,
      );
      await LocalStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await LocalStorage.saveUser(result.user.toJson());
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _dataSource.register(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        bloodType: event.bloodType,
        gender: event.gender,
        phone: event.phone,
      );
      await LocalStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await LocalStorage.saveUser(result.user.toJson());
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await LocalStorage.clear();
    emit(AuthUnauthenticated());
  }

  Future<void> _onProfileUpdated(AuthProfileUpdated event, Emitter<AuthState> emit) async {
    try {
      final user = await _dataSource.getProfile();
      await LocalStorage.saveUser(user.toJson());
      emit(AuthAuthenticated(user));
    } catch (_) {}
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('401')) return 'Invalid email or password';
    if (e.toString().contains('409')) return 'Email already registered';
    return 'Something went wrong. Please try again.';
  }
}
