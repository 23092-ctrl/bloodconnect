import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:bloodconnect/controllers/auth_controller.dart';
import 'package:bloodconnect/features/auth/presentation/pages/login_page.dart';
import 'package:bloodconnect/l10n/app_localizations.dart';
import 'package:bloodconnect/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

Widget _buildApp(AuthController auth) {
  return ChangeNotifierProvider<AuthController>.value(
    value: auth,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginPage(),
    ),
  );
}

void main() {
  late MockAuthService mockService;
  late AuthController auth;

  setUp(() {
    mockService = MockAuthService();
    auth = AuthController(mockService);
  });

  tearDown(() => auth.dispose());

  testWidgets('Login page affiche les champs email et mot de passe',
      (tester) async {
    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Login page affiche le bouton Sign In', (tester) async {
    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Validation bloque la soumission avec champs vides',
      (tester) async {
    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('Bouton désactivé pendant le chargement', (tester) async {
    when(() => mockService.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ))
        .thenAnswer((_) async {
      // Simule un délai réseau court
      await Future.delayed(const Duration(milliseconds: 50));
      throw Exception('network error');
    });

    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).first, 'test@test.com');
    await tester.enterText(
        find.byType(TextFormField).last, 'password123');

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull);

    // Avance le temps pour terminer l'async
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  });

  testWidgets('Lien vers register visible', (tester) async {
    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });
}
