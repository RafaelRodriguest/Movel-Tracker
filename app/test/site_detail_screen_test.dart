import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/models/site.dart';
import 'package:movel_tracker/providers/auth_provider.dart';
import 'package:movel_tracker/providers/site_provider.dart';
import 'package:movel_tracker/screens/site_detail_screen.dart';

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

  group('SiteDetailScreen — renderização', () {
    testWidgets('mostra nome, endereço, técnico, coordenadas, id e status',
        (tester) async {
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: _site)));
      await tester.pumpAndSettle();

      expect(find.text('São Luís Centro'), findsWidgets);
      expect(find.text('Av. Litorânea, 100'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text(_site.coordenadasFormatadas), findsOneWidget);
      expect(find.text('ID: SLZ001'), findsOneWidget);
      expect(find.text('Site Operacional'), findsOneWidget);
    });

    testWidgets('site inativo mostra badge "Site Inativo"', (tester) async {
      final inativo = Site(
        siteId: _site.siteId,
        sigla: _site.sigla,
        nome: _site.nome,
        endereco: _site.endereco,
        municipio: _site.municipio,
        uf: _site.uf,
        tecnico: _site.tecnico,
        latitude: _site.latitude,
        longitude: _site.longitude,
        detentora: _site.detentora,
        uc: _site.uc,
        status: 'Desativado',
      );
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: inativo)));
      await tester.pumpAndSettle();

      expect(find.text('Site Inativo'), findsOneWidget);
    });

    testWidgets('usuário sem perfil cell_owner não vê editar/marcador de edição de foto',
        (tester) async {
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: _site)));
      await tester.pumpAndSettle();

      // Sem sessão/perfil (isCellOwner == false por padrão em teste),
      // a seção operacional deve mostrar a mensagem read-only, sem botão "Editar".
      expect(find.text('Nenhuma informação do site registrada.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Editar'), findsNothing);
    });
  });

  group('SiteDetailScreen — responsividade', () {
    testWidgets('renderiza sem overflow em tela estreita (320px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: _site)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza sem overflow em tela larga (tablet, 1024px)', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: _site)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('nome longo não quebra o layout do topo', (tester) async {
      final nomeLongo = Site(
        siteId: _site.siteId,
        sigla: _site.sigla,
        nome: 'Site com um Nome Extremamente Longo Para Testar Ellipsis no AppBar',
        endereco: _site.endereco,
        municipio: _site.municipio,
        uf: _site.uf,
        tecnico: _site.tecnico,
        latitude: _site.latitude,
        longitude: _site.longitude,
        detentora: _site.detentora,
        uc: _site.uc,
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: nomeLongo)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('SiteDetailScreen — experiência do usuário', () {
    testWidgets('botão voltar retorna à tela anterior', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SiteDetailScreen(site: _site)),
                ),
                child: const Text('abrir detalhe'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir detalhe'));
      await tester.pumpAndSettle();
      expect(find.byType(SiteDetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(SiteDetailScreen), findsNothing);
    });

    testWidgets('tocar no ícone de copiar do card de endereço mostra confirmação',
        (tester) async {
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: _site)));
      await tester.pumpAndSettle();

      final enderecoCard = find.ancestor(
        of: find.text('Av. Litorânea, 100'),
        matching: find.byType(Row),
      ).first;
      final copyIcon = find.descendant(
        of: enderecoCard,
        matching: find.byIcon(Icons.content_copy),
      );
      await tester.ensureVisible(copyIcon);
      await tester.pumpAndSettle();
      await tester.tap(copyIcon);
      await tester.pump();

      expect(find.text('Endereço copiado'), findsOneWidget);
    });

    testWidgets('botão "INICIAR ROTA NO GOOGLE MAPS" está visível e habilitado',
        (tester) async {
      await tester.pumpWidget(_wrap(SiteDetailScreen(site: _site)));
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'INICIAR ROTA NO GOOGLE MAPS');
      expect(button, findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    });
  });
}
