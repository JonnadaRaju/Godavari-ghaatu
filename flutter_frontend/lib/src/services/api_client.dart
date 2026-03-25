import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> get(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.get(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(token: token),
    );
    return _decode(response);
  }

  Future<dynamic> post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _buildHeaders(token: token),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.put(
      _buildUri(path),
      headers: _buildHeaders(token: token),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> patch(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.patch(
      _buildUri(path),
      headers: _buildHeaders(token: token),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> delete(
    String path, {
    String? token,
  }) async {
    final response = await _client.delete(
      _buildUri(path),
      headers: _buildHeaders(token: token),
    );
    return _decode(response);
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _buildHeaders({String? token}) {
    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(http.Response response) {
    final rawBody = response.body.trim();
    final statusCode = response.statusCode;

    dynamic data;
    if (rawBody.isNotEmpty) {
      data = jsonDecode(rawBody);
    }

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    final message = _extractMessage(data) ?? 'Request failed with status $statusCode';
    throw ApiException(message, statusCode: statusCode);
  }

  String? _extractMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final detail = payload['detail'];
      if (detail != null) {
        return detail.toString();
      }
      final message = payload['message'];
      if (message != null) {
        return message.toString();
      }
    }
    return null;
  }
}
