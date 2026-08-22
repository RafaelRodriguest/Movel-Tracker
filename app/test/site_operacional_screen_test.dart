import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/models/site.dart';
import 'package:movel_tracker/providers/site_provider.dart';
import 'package:movel_tracker/screens/site_operacional_screen.dart';

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

final _site = Site(
  siteId: 'SLZ001',
  sigla: 'MASLS7',
  nome: 'São Luís Centro',
  endereco: 'Av. Litorânea, 100',
  municipio: 'São Luís',
  uf: 'MA',
  tecnico: 'João Silva',
  latitude: -2.5307,
  longitude: -44.3068,
  detentora: 'ATC',
  uc: 'UC12345',
  status: 'Ativo',
);

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => SiteProvider(),
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

  group('SiteOperacionalScreen — renderização', () {
    testWidgets('mostra título, nome do site e as 3 seções', (tester) async {
      await tester.pumpWidget(_wrap(SiteOperacionalScreen(site: _site)));
      await tester.pumpAndSettle();

      expect(find.text('Informações Operacionais'), findsOneWidget);
      expect(find.text('São Luís Centro'), findsOneWidget);
      expect(find.text('CHAVES'), findsOneWidget);
      expect(find.text('GABINETE 01'), findsOneWidget);
      expect(find.text('GABINETE 02'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'SALVAR INFORMAÇÕES'), findsOneWidget);
    });

    testWidgets('opções de chave são as do estado do site (MA)', (tester) async {
      await tester.pumpWidget(_wrap(SiteOperacionalScreen(site: _site)));
      await tester.pumpAndSettle();

      final chavePortao = find.widgetWithText(DropdownButtonFormField<String>, 'Chave Portão');
      await tester.tap(chavePortao);
      await tester.pumpAndSettle();

      expect(find.text('MA GDA').last, findsOneWidget);
      expect(find.text('PA-GD'), findsNothing);
    });
  });

  group('SiteOperacionalScreen — responsividade', () {
    testWidgets('renderiza sem overflow em tela estreita (320px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(_wrap(SiteOperacionalScreen(site: _site)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza sem overflow em tela larga (tablet, 1024px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_wrap(SiteOperacionalScreen(site: _site)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('SiteOperacionalScreen — experiência do usuário', () {
    testWidgets('selecionar fonte e digitar consumo atualiza os campos', (tester) async {
      await tester.pumpWidget(_wrap(SiteOperacionalScreen(site: _site)));
      await tester.pumpAndSettle();

      final fonte01 = find.widgetWithText(DropdownButtonFormField<String>, 'Fonte 01');
      await tester.tap(fonte01);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ELTEK 2500').last);
      await tester.pumpAndSettle();

      expect(find.text('ELTEK 2500'), findsOneWidget);

      final consumo01 = find.widgetWithText(TextFormField, 'Consumo Fonte 01');
      await tester.enterText(consumo01, '12,5');
      await tester.pump();

      expect(find.text('12,5'), findsOneWidget);
    });

    testWidgets('salvar dispara loading e depois erro de conexão', (tester) async {
      await tester.pumpWidget(_wrap(SiteOperacionalScreen(site: _site)));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Erro ao salvar. Verifique a conexão.'), findsOneWidget);
    });
  });
}
