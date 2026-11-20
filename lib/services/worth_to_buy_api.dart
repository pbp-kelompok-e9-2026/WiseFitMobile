import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/worth_to_buy.dart';
import '../models/standalone_options.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.fields = const {}});
  final String message;
  final Json fields;
  @override
  String toString() => message;
}

class WorthToBuyApi extends ChangeNotifier {
  WorthToBuyApi({
    String? baseUrl,
    http.Client? client,
    this.user,
    String? sessionToken,
  }) : baseUrl = (baseUrl ?? _defaultBaseUrl()).replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client(),
       _token = sessionToken;
  static const module = '/api/worth-to-buy/';
  final String baseUrl;
  final http.Client _client;
  String? _token;
  ApiUser? user;
  bool get hasSession => user != null;

  static String _defaultBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  Future<dynamic> _request(String method, String path, [Json? body]) async {
    if (!hasSession) {
      throw const ApiException(
        'Penyimpanan dan data server tersedia setelah sesi login bersama terhubung.',
      );
    }
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Accept'] = 'application/json';
      if (_token != null) request.headers['Authorization'] = 'Token $_token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await (() async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 30));
      if (response.statusCode == 204) return null;
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ApiException(
          'Respons server tidak valid. Periksa alamat dan kesiapan API.',
        );
      }
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      if (response.statusCode == 401) {
        _token = null;
        user = null;
        notifyListeners();
      }
      final errors = data is Json ? data : <String, dynamic>{};
      throw ApiException(
        errors['detail']?.toString() ?? 'Periksa kembali isian kamu.',
        fields: errors,
      );
    } on TimeoutException {
      throw const ApiException('Server belum merespons. Coba lagi sebentar.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi dan alamat API.',
      );
    }
  }

  Future<FormOptions> options() async => FormOptions.fromJson(
    hasSession
        ? await _request('GET', '${module}options/') as Json
        : standaloneFormOptions,
  );

  Future<ResultPage<T>> _page<T>(String path, T Function(Json) parse) async {
    final data = await _request('GET', path) as Json;
    return ResultPage(
      items: (data['results'] as List)
          .map((item) => parse(item as Json))
          .toList(),
      count: data['count'] as int,
      hasNext: data['next'] != null,
    );
  }

  Future<ResultPage<PurchaseAnalysis>> analyses(int page) =>
      _page('${module}analyses/?page=$page', PurchaseAnalysis.fromJson);
  Future<PurchaseAnalysis> analysis(int id) async => PurchaseAnalysis.fromJson(
    await _request('GET', '${module}analyses/$id/') as Json,
  );
  Future<PurchaseAnalysis> saveAnalysis(Json values, {int? id}) async =>
      PurchaseAnalysis.fromJson(
        await _request(
          id == null ? 'POST' : 'PUT',
          '${module}analyses/${id == null ? '' : '$id/'}',
          values,
        ) as Json,
      );
  Future<void> deleteAnalysis(int id) async {
    await _request('DELETE', '${module}analyses/$id/');
  }

  Future<PurchaseAnalysis> decide(int id, String decision, String note) async =>
      PurchaseAnalysis.fromJson(
        await _request('POST', '${module}analyses/$id/decision/', {
          'decision': decision,
          'decision_note': note,
        }) as Json,
      );
  Future<PurchaseAnalysis> refreshCarbon(int id) async =>
      PurchaseAnalysis.fromJson(
        await _request('POST', '${module}analyses/$id/refresh-carbon/') as Json,
      );
  Future<ResultPage<ClothingReference>> references({
    required bool workspace,
    int page = 1,
    String query = '',
    String category = '',
    String status = '',
  }) {
    final parameters = Uri(
      queryParameters: {
        'page': '$page',
        'q': query,
        'category': category,
        if (workspace) 'status': status,
      },
    ).query;
    return _page(
      '$module${workspace ? 'references' : 'catalogue'}/?$parameters',
      ClothingReference.fromJson,
    );
  }

  Future<ClothingReference> saveReference(Json values, {int? id}) async =>
      ClothingReference.fromJson(
        await _request(
          id == null ? 'POST' : 'PUT',
          '${module}references/${id == null ? '' : '$id/'}',
          values,
        ) as Json,
      );
  Future<void> deleteReference(int id) async {
    await _request('DELETE', '${module}references/$id/');
  }

  Future<ClothingReference> publish(int id, bool published) async =>
      ClothingReference.fromJson(
        await _request('POST', '${module}references/$id/publication/', {
          'is_published': published,
        }) as Json,
      );
  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
