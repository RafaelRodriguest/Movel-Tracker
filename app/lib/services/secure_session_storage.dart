import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Guarda a sessão do Supabase (access/refresh token) no Keystore/Keychain
/// em vez de SharedPreferences em texto puro — sem isso, um `adb backup`
/// ou acesso root extrai o token de sessão do usuário logado.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _key = 'supabase.auth.session';
  static const _storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<bool> hasAccessToken() async => (await _storage.read(key: _key)) != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
