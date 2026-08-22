import 'dart:async';
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
  bool _isInitializing = true;
  StreamSubscription<Uri>? _deepLinkSub;

  bool get isLoggedIn => _session != null;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPasswordRecovery => _isPasswordRecovery;
  bool get isInitializing => _isInitializing;

  static const _allowedDomains = ['claro.com.br', 'stte.com.br'];

  AuthProvider() {
    _session = _client.auth.currentSession;
    if (_session != null) _loadProfile();

    _initAsync();

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
    }, onError: (_) {});

  }

  Future<void> _initAsync() async {
    final appLinks = AppLinks();

    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) await _handleUri(initialUri);

    _deepLinkSub = appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri).catchError((_) {}),
    );

    _isInitializing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _handleUri(Uri uri) async {
    final fragmentParams = Uri.splitQueryString(uri.fragment);
    final type = uri.queryParameters['type'] ?? fragmentParams['type'];
    final errorDescription = uri.queryParameters['error_description'] ??
        fragmentParams['error_description'];
    final isRecovery = type == 'recovery' || type == 'invite';

    if (!isRecovery) {
      if (errorDescription != null) {
        _error = 'Link expirado ou já utilizado. Solicite um novo.';
        notifyListeners();
      }
      return;
    }

    try {
      await _client.auth.getSessionFromUrl(uri);
    } catch (_) {
      _error = 'Link expirado ou já utilizado. Solicite um novo.';
      notifyListeners();
      return;
    }

    if (_client.auth.currentSession != null) {
      _session = _client.auth.currentSession;
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
      final raw = await _client
          .rpc('get_email_by_login', params: {'p_login': login.trim()});
      final email = raw?.toString() ?? '';

      if (email.isEmpty) {
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

  Future<String?> sendPasswordReset(String login) async {
    try {
      final raw = await _client
          .rpc('get_email_by_login', params: {'p_login': login.trim()});
      final email = raw?.toString() ?? '';

      if (email.isEmpty) {
        return 'Login não encontrado.';
      }

      final domain = email.split('@').last.toLowerCase();
      if (!_allowedDomains.contains(domain)) {
        return 'Domínio de e-mail não autorizado.';
      }

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.claro.moveltracker://login-callback/',
      );
      return null; // sucesso
    } on AuthException catch (e) {
      return 'Erro ao enviar e-mail: ${e.message}';
    } catch (_) {
      return 'Erro inesperado. Tente novamente.';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      _isPasswordRecovery = false;
      notifyListeners();
      // Garante que o perfil esteja carregado ao ir para HomeScreen
      await _loadProfile();
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
    _error = null;
    _isPasswordRecovery = false;
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
