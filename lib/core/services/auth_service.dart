import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Authentification : appels API + persistance [StorageService] (pas d’HTTP dans les widgets).
class AuthService {
  AuthService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _api = apiService ?? ApiService(),
        _storage = storageService ?? StorageService();

  final ApiService _api;
  final StorageService _storage;

  static const Duration _loginTimeout = Duration(seconds: 20);

  static const String _networkError =
      'Impossible de joindre le serveur. Vérifiez XAMPP.';

  /// Connexion — corps JSON `{ "email", "mot_de_passe" }` attendu par l’API PHP.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api
          .post(
            ApiConstants.authLogin,
            body: {
              'email': email,
              'mot_de_passe': password,
            },
          )
          .timeout(_loginTimeout);

      final body = res.body;
      if (body.isEmpty) {
        return AuthResult.failure(_networkError);
      }

      final Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return AuthResult.failure(
          res.statusCode >= 500 ? _networkError : 'Réponse serveur invalide',
        );
      }

      if (data['success'] != true) {
        final msg = data['message'] as String? ?? 'Email ou mot de passe incorrect';
        return AuthResult.failure(msg);
      }

      final token = data['token'] as String?;
      final role = data['role'] as String?;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      // L'API peut retourner extra: [] (liste vide) pour admin
      // On convertit en Map vide si c'est une Liste
      final extraRaw = data['extra'];
      final extra = (extraRaw is Map<String, dynamic>) ? extraRaw : <String, dynamic>{};

      if (token == null || role == null) {
        return AuthResult.failure('Réponse serveur incomplète');
      }

      final id = user['id'];
      final uid = id is int ? id : int.tryParse(id.toString());
      if (uid == null) {
        return AuthResult.failure('Réponse serveur incomplète');
      }

      await _persistLoginResponse(
        token: token,
        role: role,
        userId: uid,
        nom: user['nom']?.toString() ?? '',
        email: user['email']?.toString() ?? '',
        telephone: user['telephone']?.toString() ?? '',
        extra: extra,
        roleValue: role,
      );

      return AuthResult.success();
    } on TimeoutException {
      return AuthResult.failure(_networkError);
    } on http.ClientException {
      return AuthResult.failure(_networkError);
    } catch (e) {
      if (_isNetworkIssue(e)) {
        return AuthResult.failure(_networkError);
      }
      return AuthResult.failure('Erreur : ${e.runtimeType}');
    }
  }

  Future<void> _persistLoginResponse({
    required String token,
    required String role,
    required int userId,
    required String nom,
    required String email,
    required String telephone,
    required Map<String, dynamic> extra,
    required String roleValue,
  }) async {
    final map = <String, dynamic>{
      StorageKeys.token: token,
      StorageKeys.role: role,
      StorageKeys.userId: userId,
      StorageKeys.userNom: nom,
      StorageKeys.userEmail: email,
      StorageKeys.userTelephone: telephone,
    };

    if (roleValue == 'agent') {
      map[StorageKeys.agentCodeAffiliation] =
          extra['code_affiliation'] as String? ?? extra['codeAffiliation'] as String? ?? '';
      final taux = extra['taux_commission'] ?? extra['tauxCommission'];
      if (taux != null) {
        map[StorageKeys.agentTauxCommission] = (taux is num) ? taux.toDouble() : double.tryParse('$taux') ?? 0.0;
      }
    } else if (roleValue == 'client') {
      map[StorageKeys.clientStatutCompte] =
          extra['statut_compte'] as String? ?? extra['statutCompte'] as String? ?? '';
      map[StorageKeys.clientNumeroCompte] =
          extra['numero_compte'] as String? ?? extra['numeroCompte'] as String? ?? '';
      final solde = extra['solde'];
      if (solde != null) {
        map[StorageKeys.clientSolde] = (solde is num) ? solde.toDouble() : double.tryParse('$solde') ?? 0.0;
      }
    }

    await _storage.saveSession(map);
  }

  bool _isNetworkIssue(Object e) {
    final s = e.toString();
    return s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('Connection refused') ||
        s.contains('HandshakeException') ||
        e is http.ClientException;
  }

  /// Déconnexion : suppression du token côté serveur puis effacement local.
  Future<void> logout() async {
    final token = await _storage.getString(StorageKeys.token);
    if (token != null && token.isNotEmpty) {
      try {
        await _api
            .post(ApiConstants.authLogout, token: token, body: <String, dynamic>{})
            .timeout(_loginTimeout);
      } catch (_) {
        /* on efface quand même la session locale */
      }
    }
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() => _storage.hasToken();

  Future<String?> getCurrentRole() => _storage.getString(StorageKeys.role);

  /// Profil utilisateur + champs métier selon rôle (depuis le stockage local).
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!await isLoggedIn()) return null;
    final id = await _storage.getInt(StorageKeys.userId);
    final nom = await _storage.getString(StorageKeys.userNom);
    final email = await _storage.getString(StorageKeys.userEmail);
    final tel = await _storage.getString(StorageKeys.userTelephone);
    final role = await _storage.getString(StorageKeys.role);
    if (id == null || nom == null || email == null || role == null) return null;

    final m = <String, dynamic>{
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': tel ?? '',
      'role': role,
    };

    if (role == 'agent') {
      m['code_affiliation'] = await _storage.getString(StorageKeys.agentCodeAffiliation);
      m['taux_commission'] = await _storage.getDouble(StorageKeys.agentTauxCommission);
    } else if (role == 'client') {
      m['statut_compte'] = await _storage.getString(StorageKeys.clientStatutCompte);
      m['numero_compte'] = await _storage.getString(StorageKeys.clientNumeroCompte);
      m['solde'] = await _storage.getDouble(StorageKeys.clientSolde);
    }

    return m;
  }

  /// Recharge l’état applicatif depuis SharedPreferences (sans appel HTTP).
  Future<SessionSnapshot> loadSessionFromStorage() async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) {
      return const SessionSnapshot(isLoggedIn: false);
    }
    final role = await getCurrentRole();
    final user = await getCurrentUser();
    final id = await _storage.getInt(StorageKeys.userId);
    return SessionSnapshot(
      isLoggedIn: true,
      role: role,
      userId: id,
      currentUser: user,
    );
  }
}

class AuthResult {
  const AuthResult._({required this.ok, this.message});

  final bool ok;
  final String? message;

  factory AuthResult.success() => const AuthResult._(ok: true);

  factory AuthResult.failure(String message) => AuthResult._(ok: false, message: message);
}

class SessionSnapshot {
  const SessionSnapshot({
    required this.isLoggedIn,
    this.role,
    this.userId,
    this.currentUser,
  });

  final bool isLoggedIn;
  final String? role;
  final int? userId;
  final Map<String, dynamic>? currentUser;
}
