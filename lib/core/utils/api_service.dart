import 'package:dio/dio.dart';

import 'app_constants.dart';

/// Thin HTTP wrapper used by remote data sources (AI photo verification,
/// feedback sync, analytics...). Not called yet — every feature currently
/// runs on mock data sources — but the contract is ready.
class ApiService {
  ApiService(this._dio) {
    _dio.options
      ..baseUrl = AppConstants.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 20)
      ..headers = {'Content-Type': 'application/json'};
  }

  final Dio _dio;

  Future<Map<String, dynamic>> get({required String endPoint, Map<String, dynamic>? query}) async {
    final response = await _dio.get<Map<String, dynamic>>(endPoint, queryParameters: query);
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> post({required String endPoint, Object? body}) async {
    final response = await _dio.post<Map<String, dynamic>>(endPoint, data: body);
    return response.data ?? const {};
  }

  /// Multipart upload (e.g. the clean-sink photo for AI verification).
  Future<Map<String, dynamic>> uploadFile({
    required String endPoint,
    required String filePath,
    String field = 'file',
  }) async {
    final form = FormData.fromMap({field: await MultipartFile.fromFile(filePath)});
    final response = await _dio.post<Map<String, dynamic>>(endPoint, data: form);
    return response.data ?? const {};
  }
}
