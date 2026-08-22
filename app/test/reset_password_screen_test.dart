import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/providers/auth_provider.dart';
import 'package:movel_tracker/screens/reset_password_screen.dart';

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

  group('ResetPasswordScreen — renderização', () {
    testWidgets('mostra título e campos de nova senha/confirmação', (tester) async {
      await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Definir nova senha'), findsOneWidget);
      expect(find.text('Nova senha'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Salvar senha'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen — responsividade', () {
    testWidgets('renderiza sem overflow em tela estreita (320px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza sem overflow em tela larga (tablet, 1024px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ResetPasswordScreen — experiência do usuário', () {
    testWidgets('alterna visibilidade de ambos os campos de senha', (tester) async {
      await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('senha curta mostra erro de validação sem chamar rede', (tester) async {
      await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Nova senha'), '123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirmar senha'), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar senha'));
      await tester.pump();

      expect(find.text('A senha deve ter pelo menos 6 caracteres.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('senhas diferentes mostram erro de validação sem chamar rede',
        (tester) async {
      await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Nova senha'), 'senha123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirmar senha'), 'outrasenha');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar senha'));
      await tester.pump();

      expect(find.text('As senhas não coincidem.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('senhas válidas e iguais disparam chamada e mostra erro de rede',
        (tester) async {
      await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Nova senha'), 'senha123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirmar senha'), 'senha123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar senha'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
