import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site.dart';

List<Site> _parseSitesJson(String raw) {
  final list = jsonDecode(raw) as List;
  return list.map((e) => Site.fromJson(e as Map<String, dynamic>)).toList();
}

class CacheService {
  /// Tag do ambiente atual ('prod' ou 'dev'), setada em main()/main_dev.dart
  /// antes do primeiro uso. Necessária porque os dois builds compartilham o
  /// mesmo applicationId Android e, portanto, o mesmo SharedPreferences —
  /// sem isso, o cache de um ambiente vaza para o outro.
  static String envTag = 'prod';

  // v3: cache escopado por ambiente + estado. O bump invalida o cache v2
  // (sem tag de ambiente), que podia misturar dados de prod e dev.
  static String _keyData(String uf) => 'sites_cache_${envTag}_${uf}_v3';
  static String _keyTimestamp(String uf) => 'sites_cache_ts_${envTag}_${uf}_v3';
  static const _ttl = Duration(minutes: 30);

  /// Retorna lista de sites do estado a partir do cache, se existir e não
  /// estiver expirado. Retorna null se cache estiver vazio, expirado ou corrompido.
  Future<List<Site>?> loadSites(String uf) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyTimestamp(uf));
    if (ts == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > _ttl.inMilliseconds) return null;
    final raw = prefs.getString(_keyData(uf));
    if (raw == null) return null;
    try {
      return await compute(_parseSitesJson, raw);
    } catch (_) {
      // Cache corrompido — limpa e força re-fetch
      await clear(uf);
      return null;
    }
  }

  /// Persiste a lista de sites do estado com timestamp atual.
  Future<void> saveSites(String uf, List<Site> sites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyData(uf),
      jsonEncode(sites.map((s) => s.toJson()).toList()),
    );
    await prefs.setInt(
      _keyTimestamp(uf),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Invalida o cache do estado — próxima abertura buscará do Supabase.
  Future<void> clear(String uf) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyData(uf));
    await prefs.remove(_keyTimestamp(uf));
  }
}
