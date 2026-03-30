import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';

class AdminService {
  AdminService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _api = apiService ?? ApiService(),
        _storage = storageService ?? StorageService();

  final ApiService _api;
  final StorageService _storage;

  Future<String?> _getToken() async {
    return _storage.getString(StorageKeys.token);
  }

  /// Dashboard admin
  Future<Map<String, dynamic>> getDashboard() async {
    final token = await _getToken();
    final response = await _api.get('/admin/dashboard', token: token);
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }
    return data['data'] as Map<String, dynamic>;
  }

  /// Clients en attente
  Future<List<dynamic>> getClientsAttente() async {
    final token = await _getToken();
    final response = await _api.get('/admin/clients/attente', token: token);
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }
    return data['data'] as List<dynamic>;
  }

  /// Valider un client
  Future<bool> validerClient(int id) async {
    final token = await _getToken();
    final response = await _api.post('/admin/clients/$id/valider', token: token);
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// Rejeter un client
  Future<bool> rejeterClient(int id) async {
    final token = await _getToken();
    final response = await _api.post('/admin/clients/$id/rejeter', token: token);
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// Liste des agents
  Future<List<dynamic>> getAgents() async {
    final token = await _getToken();
    final response = await _api.get('/admin/agents', token: token);
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }
    return data['data'] as List<dynamic>;
  }

  /// Créer un agent
  Future<bool> creerAgent(Map<String, dynamic> agentData) async {
    final token = await _getToken();
    final response = await _api.post('/admin/agents', token: token, body: agentData);
    
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(data?['message'] ?? 'Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// Modifier statut agent
  Future<bool> modifierStatutAgent(int id, String statut) async {
    final token = await _getToken();
    final response = await _api.post(
      '/admin/agents/$id/statut', 
      token: token, 
      body: {'statut': statut}
    );
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// Rapports
  Future<Map<String, dynamic>> getRapports() async {
    final token = await _getToken();
    final response = await _api.get('/admin/rapports', token: token);
    
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }
    return data['data'] as Map<String, dynamic>;
  }
}
