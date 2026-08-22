import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/providers/auth_provider.dart';
import 'package:movel_tracker/providers/site_provider.dart';
import 'package:movel_tracker/screens/home_screen.dart';
import 'package:movel_tracker/screens/state_selection_screen.dart';

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

Widget _wrap(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SiteProvider()),
      ],
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

  group('StateSelectionScreen — renderização', () {
    testWidgets('mostra os 5 estados atendidos como "Disponível"', (tester) async {
      await tester.pumpWidget(_wrap(const StateSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Selecione o estado'), findsOneWidget);
      expect(find.text('Maranhão'), findsOneWidget);
      expect(find.text('Pará'), findsOneWidget);
      expect(find.text('Amazonas'), findsOneWidget);
      expect(find.text('Roraima'), findsOneWidget);
      expect(find.text('Amapá'), findsOneWidget);
      expect(find.text('Disponível'), findsNWidgets(5));
    });
  });

  group('StateSelectionScreen — responsividade', () {
    testWidgets('renderiza sem overflow em tela estreita (320px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(_wrap(const StateSelectionScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza sem overflow em tela larga (tablet, 1024px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_wrap(const StateSelectionScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('StateSelectionScreen — experiência do usuário', () {
    testWidgets('tocar em um card de estado disponível navega para HomeScreen',
        (tester) async {
      await tester.pumpWidget(_wrap(const StateSelectionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maranhão'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('menu de opções mostra "Sair"', (tester) async {
      await tester.pumpWidget(_wrap(const StateSelectionScreen()));
      await tester.pumpAndSettle();

      final menuButton = find.byIcon(Icons.account_circle);
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.text('Sair'), findsOneWidget);
    });
  });
}
