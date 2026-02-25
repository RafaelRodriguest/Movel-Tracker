import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movel_tracker/providers/site_provider.dart';
import 'package:movel_tracker/screens/home_screen.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late SiteProvider provider;

    setUp(() {
      provider = SiteProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    testWidgets('Deve renderizar HomeScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SiteProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Movel Tracker'), findsOneWidget);
      expect(find.byIcon(Icons.cell_tower), findsOneWidget);
    });

    testWidgets('Deve mostrar barra de busca', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SiteProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Deve mostrar ícone de torre no header', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SiteProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.cell_tower), findsOneWidget);
    });

    testWidgets('Deve mostrar botão de voltar no header', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SiteProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });
  });
}
