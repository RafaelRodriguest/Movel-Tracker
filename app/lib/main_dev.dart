import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env_dev.dart';
import 'main.dart';
import 'services/cache_service.dart';

/// Entrypoint de desenvolvimento — conecta ao projeto Supabase de dev, não ao
/// de produção. Rodar com `flutter run -t lib/main_dev.dart`.
/// Ver CLAUDE.md, seção "Ambiente de desenvolvimento".
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CacheService.envTag = 'dev';
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
  runApp(const ClaroSitesApp(isDev: true));
}
