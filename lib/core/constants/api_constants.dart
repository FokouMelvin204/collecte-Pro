import 'package:flutter/foundation.dart' show kIsWeb;

/// Constantes liées à l'API REST PHP (Collecte Pro).
class ApiConstants {
  ApiConstants._();

  /// Base URL de l'API.
  /// - Flutter Web : localhost
  /// - Android émulateur : 10.0.2.2 (localhost de la machine hôte)
  /// - iOS / appareil physique : utiliser l'IP LAN de la machine
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/collectepro/api';
    }
    return 'http://10.0.2.2/collectepro/api';
  }

  /// Préfixe optionnel pour routes REST (sans slash final — géré par [ApiService]).
  static const String apiPrefix = '';

  // ——— Routes auth (exemples pour les prochains modules) ———
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
}
