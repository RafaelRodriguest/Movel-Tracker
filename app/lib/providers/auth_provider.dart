import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final _client = Supabase.instance.client;

  Session? _session;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  bool _isPasswordRecovery = false;

  bool get isLoggedIn => _session != null;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPasswordRecovery => _isPasswordRecovery;

  static const _allowedDomains = ['claro.com.br', 'stte.com.br'];

  AuthProvider() {
    _session = _client.auth.currentSession;
    if (_session != null) _loadProfile();

    _client.auth.onAuthStateChange.listen((data) {
      _session = data.session;

      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        notifyListeners();
        return;
      }

      if (data.event == AuthChangeEvent.userUpdated) {
        _isPasswordRecovery = false;
      }

      if (_session != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });

    // Detecta deep link diretamente — cobre cold start e warm start
    _listenDeepLinks();
  }

  void _listenDeepLinks() {
    final appLinks = AppLinks();

    // Cold start: app aberto pelo link
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });

    // Warm start: app já aberto, link clicado
    appLinks.uriLinkStream.listen(_handleUri);
  }

  Future<void> _handleUri(Uri uri) async {
    final params = Uri.splitQueryString(uri.fragment);
    if (params['type'] == 'recovery') {
      try {
        // Estabelece a sessão a partir do token do link antes de mostrar a tela
        await _client.auth.getSessionFromUrl(uri);
      } catch (_) {}
      _isPasswordRecovery = true;
      notifyListeners();
    }
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

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      _isPasswordRecovery = false;
      notifyListeners();
      return null; // sucesso
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Erro ao atualizar senha.';
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
