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

  Future<List<String?>> fetchSiteFotos(String siteId) async {
    final data = await _client
        .from('sites')
        .select('foto_1, foto_2, foto_3, foto_4, foto_5')
        .eq('site_id', siteId)
        .single();
    return [
      data['foto_1'] as String?,
      data['foto_2'] as String?,
      data['foto_3'] as String?,
      data['foto_4'] as String?,
      data['foto_5'] as String?,
    ];
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

  Future<void> updateInformacoesOperacionais(
    String siteId, {
    String? chavePortao,
    String? chaveGradil01,
    String? chaveGradil02,
    String? fonte01,
    String? fonte02,
    String? consumoFonte01,
    String? consumoFonte02,
    String? bateriasFonte01,
    String? bateriasFonte02,
  }) async {
    await _client.from('sites').update({
      'chave_portao': chavePortao,
      'chave_gradil_01': chaveGradil01,
      'chave_gradil_02': chaveGradil02,
      'fonte_01': fonte01,
      'fonte_02': fonte02,
      'consumo_fonte_01': consumoFonte01,
      'consumo_fonte_02': consumoFonte02,
      'baterias_fonte_01': bateriasFonte01,
      'baterias_fonte_02': bateriasFonte02,
    }).eq('site_id', siteId);

    await insertAuditLog(
      siteId: siteId,
      action: 'operacional_update',
      detail: 'chaves/fontes/consumo/baterias atualizados',
    );
  }

  /// Chama a edge function para deletar a imagem do Cloudinary.
  /// Operação best-effort: falhas são silenciadas para não bloquear o fluxo principal.
  Future<void> deleteCloudinaryImage(String publicId) async {
    try {
      await _client.functions.invoke(
        'delete-cloudinary-image',
        body: {'public_id': publicId},
      );
    } catch (_) {
      // Falha silenciosa — imagem órfã no Cloudinary é aceitável
    }
  }

  Future<void> insertAuditLog({
    required String siteId,
    required String action,
    String? detail,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('audit_log').insert({
      'user_id': userId,
      'site_id': siteId,
      'action': action,
      'detail': detail,
    });
  }
}
