import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site.dart';

class CacheService {
  static const _keyData = 'sites_cache_v1';
  static const _keyTimestamp = 'sites_cache_ts_v1';
  static const _ttl = Duration(minutes: 30);

  /// Retorna lista de sites do cache se existir e não estiver expirado.
  /// Retorna null se cache estiver vazio, expirado ou corrompido.
  Future<List<Site>?> loadSites() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyTimestamp);
    if (ts == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > _ttl.inMilliseconds) return null;
    final raw = prefs.getString(_keyData);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Site.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Cache corrompido — limpa e força re-fetch
      await clear();
      return null;
    }
  }

  /// Persiste a lista de sites com timestamp atual.
  Future<void> saveSites(List<Site> sites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyData,
      jsonEncode(sites.map((s) => s.toJson()).toList()),
    );
    await prefs.setInt(
      _keyTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Invalida o cache — próxima abertura buscará do Supabase.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyData);
    await prefs.remove(_keyTimestamp);
  }
}
