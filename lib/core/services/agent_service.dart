import 'dart:convert';

import '../models/dashboard_agent_model.dart';
import '../models/client_model.dart';
import '../models/commission_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service pour les appels API liés aux agents.
class AgentService {
  AgentService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _api = apiService ?? ApiService(),
        _storage = storageService ?? StorageService();

  final ApiService _api;
  final StorageService _storage;

  /// Récupère le dashboard de l'agent.
  Future<DashboardAgentModel> getDashboard() async {
    final token = await _storage.getString(StorageKeys.token);
    final response = await _api.get('/agent/dashboard', token: token);

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    return DashboardAgentModel.fromJson(data);
  }

  /// Récupère la liste des clients de l'agent.
  Future<List<ClientModel>> getClients() async {
    final token = await _storage.getString(StorageKeys.token);
    final response = await _api.get('/agent/clients', token: token);

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    final dataList = data['data'] as List? ?? [];
    return dataList
        .map((c) => ClientModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les commissions de l'agent.
  Future<CommissionsDataModel> getCommissions() async {
    final token = await _storage.getString(StorageKeys.token);
    final response = await _api.get('/agent/commissions', token: token);

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    return CommissionsDataModel.fromJson(data);
  }

  /// Récupère le profil de l'agent.
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _storage.getString(StorageKeys.token);
    final response = await _api.get('/agent/profile', token: token);

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    return data['data'] as Map<String, dynamic>? ?? {};
  }
}
