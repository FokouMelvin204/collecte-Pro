import 'package:shared_preferences/shared_preferences.dart';

/// Clés SharedPreferences (noms exacts demandés par le cahier des charges).
abstract class StorageKeys {
  StorageKeys._();

  static const String token = 'token';
  static const String role = 'role';
  static const String userId = 'user_id';
  static const String userNom = 'user_nom';
  static const String userEmail = 'user_email';
  static const String userTelephone = 'user_telephone';
  static const String agentCodeAffiliation = 'agent_code_affiliation';
  static const String agentTauxCommission = 'agent_taux_commission';
  static const String clientStatutCompte = 'client_statut_compte';
  static const String clientNumeroCompte = 'client_numero_compte';
  static const String clientSolde = 'client_solde';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
}

/// Persistance locale de session (aucun mot de passe stocké).
class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('StorageService non initialisé. Appelez init() au démarrage.');
    }
    return _prefs!;
  }

  static const _allKeys = <String>{
    StorageKeys.token,
    StorageKeys.role,
    StorageKeys.userId,
    StorageKeys.userNom,
    StorageKeys.userEmail,
    StorageKeys.userTelephone,
    StorageKeys.agentCodeAffiliation,
    StorageKeys.agentTauxCommission,
    StorageKeys.clientStatutCompte,
    StorageKeys.clientNumeroCompte,
    StorageKeys.clientSolde,
  };

  Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = _instance;
    for (final e in data.entries) {
      final k = e.key;
      final v = e.value;
      if (v == null) continue;
      if (v is String) {
        await prefs.setString(k, v);
      } else if (v is int) {
        await prefs.setInt(k, v);
      } else if (v is double) {
        await prefs.setDouble(k, v);
      } else if (v is bool) {
        await prefs.setBool(k, v);
      } else {
        await prefs.setString(k, v.toString());
      }
    }
  }

  Future<void> clearSession() async {
    final prefs = _instance;
    for (final k in _allKeys) {
      await prefs.remove(k);
    }
  }

  Future<void> setBool(String key, bool value) async {
    await _instance.setBool(key, value);
  }

  Future<String?> getString(String key) async {
    return _instance.getString(key);
  }

  Future<double?> getDouble(String key) async {
    return _instance.getDouble(key);
  }

  Future<bool?> getBool(String key) async {
    return _instance.getBool(key);
  }

  Future<int?> getInt(String key) async {
    return _instance.getInt(key);
  }

  /// Indique si un jeton est présent (session locale).
  Future<bool> hasToken() async {
    final t = await getString(StorageKeys.token);
    return t != null && t.isNotEmpty;
  }
}
