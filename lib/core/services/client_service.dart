import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../models/dashboard_client_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service pour les appels API liés aux clients.
class ClientService {
  ClientService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _api = apiService ?? ApiService(),
        _storage = storageService ?? StorageService();

  final ApiService _api;
  final StorageService _storage;

  /// Récupère le dashboard du client.
  Future<DashboardClientModel> getDashboard() async {
    final token = await _storage.getString(StorageKeys.token);

    // ── LOGS TEMPORAIRES DE DIAGNOSTIC ──
    debugPrint('=== CLIENT DASHBOARD DEBUG ===');
    debugPrint('Token: ${token ?? "NULL - PAS DE TOKEN"}');
    debugPrint('URL: ${ApiConstants.baseUrl}/client/dashboard');
    // ────────────────────────────────────

    if (token == null || token.isEmpty) {
      throw Exception('Token manquant — reconnectez-vous');
    }

    final response = await _api.get('/client/dashboard', token: token);

    debugPrint('Status code: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
    debugPrint('Headers: ${response.request?.headers}');

    if (response.statusCode == 404) {
      throw Exception('Route introuvable. Vérifiez que XAMPP est démarré.');
    }
    if (response.statusCode == 401) {
      throw Exception('Session expirée. Reconnectez-vous.');
    }
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    return DashboardClientModel.fromJson(data);
  }

  /// Effectue un versement.
  Future<Map<String, dynamic>> effectuerVersement(double montant) async {
    final token = await _storage.getString(StorageKeys.token);
    final response = await _api.post(
      '/client/versement',
      token: token,
      body: {'montant': montant},
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(data?['message'] ?? 'Erreur serveur');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    return data;
  }

  /// Récupère l'historique des transactions.
  Future<Map<String, dynamic>> getHistorique() async {
    final token = await _storage.getString(StorageKeys.token);
    final response = await _api.get('/client/historique', token: token);

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    return data;
  }
}
