import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claro_sites_ma/models/site.dart';
import 'package:claro_sites_ma/screens/site_detail_screen.dart';

void main() {
  group('SiteDetailScreen Widget Tests', () {
    late Site testSite;

    setUp(() {
      testSite = Site(
        siteId: 'SLZ001',
        sigla: 'MASLS7',
        nome: 'São Luís Centro',
        endereco: 'Av. Dom Pedro II, 100, Centro',
        municipio: 'São Luís',
        tecnico: 'João Silva',
        latitude: -2.5297,
        longitude: -44.3028,
        detentora: 'ATC',
        uc: '12345678',
        tecnologias: ['4G', '5G'],
        status: 'Ativo',
      );
    });

    testWidgets('Deve renderizar SiteDetailScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.text(testSite.nome), findsWidgets);
      expect(find.text('ID: ${testSite.siteId}'), findsOneWidget);
    });

    testWidgets('Deve mostrar nome do site', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.text(testSite.nome), findsWidgets);
    });

    testWidgets('Deve mostrar status operacional', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.text('Site Operacional'), findsOneWidget);
    });

    testWidgets('Deve mostrar "Site Inativo" quando status não é ativo', (WidgetTester tester) async {
      final inativoSite = Site(
        siteId: 'SLZ001',
        sigla: 'MASLS7',
        nome: 'Test',
        endereco: 'Test',
        municipio: 'Test',
        tecnico: 'Test',
        latitude: -2.5,
        longitude: -44.5,
        detentora: 'ATC',
        uc: '123',
        tecnologias: ['4G'],
        status: 'inativo',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: inativoSite),
        ),
      );

      await tester.pump();

      expect(find.text('Site Inativo'), findsOneWidget);
    });

    testWidgets('Deve mostrar técnico', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.text('Técnico'), findsOneWidget);
      expect(find.text(testSite.tecnico), findsOneWidget);
    });

    testWidgets('Deve mostrar coordenadas', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.text('Coordenadas'), findsOneWidget);
      expect(find.text(testSite.coordenadasFormatadas), findsOneWidget);
    });

    testWidgets('Deve mostrar tecnologias', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.text('Tecnologias Disponíveis'), findsOneWidget);

      for (final tech in testSite.tecnologias) {
        expect(find.text(tech), findsOneWidget);
      }
    });

    testWidgets('Deve mostrar botão de rota no Google Maps', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.text('INICIAR ROTA NO GOOGLE MAPS'), findsOneWidget);
      expect(find.byIcon(Icons.directions), findsOneWidget);
    });

    testWidgets('Deve mostrar botão de voltar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Deve mostrar botão de compartilhar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailScreen(site: testSite),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}
