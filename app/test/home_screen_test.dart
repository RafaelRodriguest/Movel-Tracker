import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/providers/auth_provider.dart';
import 'package:movel_tracker/providers/site_provider.dart';
import 'package:movel_tracker/screens/home_screen.dart';
import 'package:movel_tracker/screens/site_detail_screen.dart';

// Mesmo padrão de site_provider_test.dart / site_repository_test.dart:
// Supabase inalcançável de propósito — o fetch falha na hora e o provider
// cai no fallback mock (5 sites do MA), que é o que dá para testar sem rede.
Future<void> _initSupabaseFake() => Supabase.initialize(
      url: 'http://localhost:1/',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );

// AuthProvider dispara o plugin app_links no construtor (deep link de reset
// de senha). Sem handler mockado, o MethodChannel/EventChannel lançam
// MissingPluginException não capturada e derrubam o teste — não é usado por
// nenhum caso aqui, então só respondemos null/sem-op.
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
        ChangeNotifierProvider(create: (_) => SiteProvider()..selectUf('MA')),
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

  group('HomeScreen — renderização do card', () {
    testWidgets('mostra detentora, nome, município/UF, UC, técnico e status',
        (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(uf: 'MA', nomeEstado: 'Maranhão')));
      await tester.pumpAndSettle();

      expect(find.text('São Luís Centro'), findsOneWidget);
      expect(find.text('ATC'), findsWidgets); // detentora repete em vários cards
      expect(find.text('São Luís, MA'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Ativo'), findsWidgets);

      // Caxias Norte (status 'Desativado') fica fora da viewport inicial —
      // rola a lista principal (CustomScrollView) até o card renderizar,
      // antes de checar o badge "Inativo". Há mais de um Scrollable na tela
      // (a lista de chips de município é horizontal), por isso o alvo precisa
      // ser explícito.
      await tester.scrollUntilVisible(
        find.text('Caxias Norte'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Inativo'), findsWidgets);
    });
  });

  group('HomeScreen — responsividade', () {
    testWidgets('lista renderiza sem overflow em tela estreita (320px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(_wrap(const HomeScreen(uf: 'MA', nomeEstado: 'Maranhão')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('lista renderiza sem overflow em tela larga (tablet, 1024px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_wrap(const HomeScreen(uf: 'MA', nomeEstado: 'Maranhão')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });

  group('HomeScreen — experiência do usuário', () {
    testWidgets('busca filtra a lista em tempo real', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(uf: 'MA', nomeEstado: 'Maranhão')));
      await tester.pumpAndSettle();

      expect(find.text('Imperatriz Matriz'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Imperatriz');
      await tester.pumpAndSettle();

      expect(find.text('Imperatriz Matriz'), findsOneWidget);
      expect(find.text('São Luís Centro'), findsNothing);
    });

    testWidgets('busca sem resultado mostra estado vazio', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(uf: 'MA', nomeEstado: 'Maranhão')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'site-que-nao-existe');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum site encontrado'), findsOneWidget);
    });

    testWidgets('chip de município filtra a lista', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(uf: 'MA', nomeEstado: 'Maranhão')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Caxias'));
      await tester.pumpAndSettle();

      expect(find.text('Caxias Norte'), findsOneWidget);
      expect(find.text('São Luís Centro'), findsNothing);
    });

    testWidgets('tocar no card navega para o detalhe do site', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(uf: 'MA', nomeEstado: 'Maranhão')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('São Luís Centro'));
      await tester.pumpAndSettle();

      expect(find.byType(SiteDetailScreen), findsOneWidget);
    });
  });
}
