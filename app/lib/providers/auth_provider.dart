import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final _client = Supabase.instance.client;

  Session? _session;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _session != null;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const _allowedDomains = ['claro.com.br', 'stte.com.br'];

  AuthProvider() {
    _session = _client.auth.currentSession;
    if (_session != null) _loadProfile();

    _client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      if (_session != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String login, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Busca o e-mail via RPC (bypassa RLS pois usuário ainda não está autenticado)
      final email = await _client
          .rpc('get_email_by_login', params: {'p_login': login.trim()});

      if (email == null || (email as String).isEmpty) {
        _error = 'Login não encontrado.';
        return;
      }

      // Valida domínio
      final domain = email.split('@').last.toLowerCase();
      if (!_allowedDomains.contains(domain)) {
        _error = 'Domínio de e-mail não autorizado.';
        return;
      }

      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      _error = e.message.contains('Invalid login')
          ? 'Senha incorreta.'
          : 'Erro ao entrar: ${e.message}';
    } catch (e) {
      _error = 'Erro inesperado. Tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _profile = null;
    _session = null;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', _client.auth.currentUser!.id)
          .single();
      _profile = UserProfile.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }
}
