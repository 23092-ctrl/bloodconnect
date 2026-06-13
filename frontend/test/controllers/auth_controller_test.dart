import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bloodconnect/controllers/auth_controller.dart';
import 'package:bloodconnect/models/user_model.dart';
import 'package:bloodconnect/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

final _fakeUser = UserModel(
  id: 'u1',
  fullName: 'Ahmed Vall',
  email: 'ahmed@test.com',
  notificationsEnabled: true,
  medicallyEligible: true,
  role: 'donor',
);

void main() {
  late Directory tempDir;
  late MockAuthService mockService;
  late AuthController controller;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox('auth');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() {
    mockService = MockAuthService();
    controller = AuthController(mockService);
  });

  tearDown(() async {
    await Hive.box('auth').clear();
    controller.dispose();
  });

  group('AuthController — état initial', () {
    test('status est initial', () {
      expect(controller.status, AuthStatus.initial);
    });

    test('user est null', () {
      expect(controller.user, isNull);
    });

    test('isAuthenticated retourne false', () {
      expect(controller.isAuthenticated, isFalse);
    });

    test('isLoading retourne false', () {
      expect(controller.isLoading, isFalse);
    });
  });

  group('AuthController — login', () {
    test('login réussi → status authenticated, user défini', () async {
      when(() => mockService.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ))
          .thenAnswer((_) async => (
                user: _fakeUser,
                accessToken: 'token123',
                refreshToken: 'refresh123',
              ));

      await controller.login('ahmed@test.com', 'password123');

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.user, isNotNull);
      expect(controller.user!.fullName, 'Ahmed Vall');
      expect(controller.isAuthenticated, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('login échoué → status error, errorMessage défini', () async {
      when(() => mockService.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ))
          .thenThrow(Exception('401 Unauthorized'));

      await controller.login('bad@test.com', 'wrong');

      expect(controller.status, AuthStatus.error);
      expect(controller.errorMessage, isNotNull);
      expect(controller.isAuthenticated, isFalse);
    });

    test('pendant le login → status loading', () async {
      when(() => mockService.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return (
          user: _fakeUser,
          accessToken: 'token',
          refreshToken: 'refresh',
        );
      });

      final statuses = <AuthStatus>[];
      controller.addListener(() => statuses.add(controller.status));

      await controller.login('ahmed@test.com', 'pass');

      expect(statuses, containsAllInOrder([
        AuthStatus.loading,
        AuthStatus.authenticated,
      ]));
    });
  });

  group('AuthController — logout', () {
    test('logout → status unauthenticated, user null', () async {
      when(() => mockService.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ))
          .thenAnswer((_) async => (
                user: _fakeUser,
                accessToken: 'token',
                refreshToken: 'refresh',
              ));

      await controller.login('ahmed@test.com', 'pass');
      expect(controller.isAuthenticated, isTrue);

      await controller.logout();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.user, isNull);
      expect(controller.isAuthenticated, isFalse);
    });
  });

  group('AuthController — checkAuth', () {
    test('checkAuth sans token → unauthenticated', () async {
      await controller.checkAuth();
      expect(controller.status, AuthStatus.unauthenticated);
    });
  });

  group('AuthController — clearError', () {
    test('clearError efface le message', () async {
      when(() => mockService.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ))
          .thenThrow(Exception('401'));

      await controller.login('bad@test.com', 'wrong');
      expect(controller.errorMessage, isNotNull);

      controller.clearError();
      expect(controller.errorMessage, isNull);
    });
  });
}
