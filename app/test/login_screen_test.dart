import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/providers/auth_provider.dart';
import 'package:movel_tracker/screens/login_screen.dart';

// Mesmo padrão de home_screen_test.dart: Supabase inalcançável de propósito.
Future<void> _initSupabaseFake() => Supabase.initialize(
      url: 'http://localhost:1/',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );

void _mockAppLinksChannels() {
  final messenger = TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
  const messages = MethodChannel('com.llfbandit.app_links/messages');
  const events = MethodChannel('com.llfbandit.app_links/events');
  messenger.setMockMethodCallHandler(messages, (_) async => null);
  messenger.setMockMethodCallHandler(events, (_) async => null);
}

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await _initSupabaseFake();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockAppLinksChannels();
  });

  group('LoginScreen — renderização', () {
    testWidgets('mostra logo, título e campos de login/senha', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Movel Tracker'), findsOneWidget);
      expect(find.text('Número de login'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    });
  });

  group('LoginScreen — responsividade', () {
    testWidgets('renderiza sem overflow em tela estreita (320px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza sem overflow em tela larga (tablet, 1024px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('LoginScreen — experiência do usuário', () {
    testWidgets('alterna visibilidade da senha', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('submeter com campos vazios não dispara chamada de rede (sem erro exibido)',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('submeter com campos preenchidos dispara chamada e mostra erro',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Número de login'), '12345');
      await tester.enterText(find.widgetWithText(TextField, 'Senha'), 'senha123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('"Esqueci minha senha" abre bottom sheet com login pré-preenchido',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Número de login'), '98765');
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar senha'), findsOneWidget);
      expect(find.text('98765'), findsNWidgets(2));

      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
