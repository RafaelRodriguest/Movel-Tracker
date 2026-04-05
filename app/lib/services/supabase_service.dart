import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  Future<List<Site>> fetchSites() async {
    final data = await _client.from('sites').select().order('nome');
    return (data as List)
        .map((row) => Site.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateFoto(String siteId, int index, String url) async {
    await _client
        .from('sites')
        .update({'foto_${index + 1}': url})
        .eq('site_id', siteId);
  }

  Future<void> deleteFoto(String siteId, int index) async {
    await _client
        .from('sites')
        .update({'foto_${index + 1}': null})
        .eq('site_id', siteId);
  }
}
