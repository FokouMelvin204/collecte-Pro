import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Client HTTP générique pour l’API Collecte Pro (aucune logique métier ici).
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) {
    final base = ApiConstants.baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Map<String, String> _headers({String? token, Map<String, String>? extra}) {
    final h = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      ...?extra,
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// GET JSON
  Future<http.Response> get(
    String path, {
    String? token,
    Map<String, String>? headers,
  }) {
    return _client.get(_uri(path), headers: _headers(token: token, extra: headers));
  }

  /// POST JSON (body encodé en UTF-8)
  Future<http.Response> post(
    String path, {
    Object? body,
    String? token,
    Map<String, String>? headers,
  }) {
    return _client.post(
      _uri(path),
      headers: _headers(token: token, extra: headers),
      body: body == null ? null : jsonEncode(body),
    );
  }

  /// PUT JSON
  Future<http.Response> put(
    String path, {
    Object? body,
    String? token,
    Map<String, String>? headers,
  }) {
    return _client.put(
      _uri(path),
      headers: _headers(token: token, extra: headers),
      body: body == null ? null : jsonEncode(body),
    );
  }

  void dispose() {
    _client.close();
  }
}
