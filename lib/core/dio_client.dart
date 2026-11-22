import 'package:dio/dio.dart';
import 'storage_config.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: StorageConfig.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<Response> get(String path, {Map<String, String>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      // Fallback or rethrow handled by repository/datasource
      rethrow;
    }
  }

  Future<Response> post(String path, {Map<String, String>? queryParameters, dynamic data}) async {
    try {
      return await _dio.post(path, queryParameters: queryParameters, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {Map<String, String>? queryParameters, dynamic data}) async {
    try {
      return await _dio.put(path, queryParameters: queryParameters, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {Map<String, String>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }
}
