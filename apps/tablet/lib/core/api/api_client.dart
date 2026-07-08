import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl, String? token})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

  final Dio _dio;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  Future<Response<List<int>>> downloadBytes(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    String? idempotencyKey,
  }) {
    return _dio.post(
      path,
      data: data,
      options: Options(headers: _idempotencyHeaders(idempotencyKey)),
    );
  }

  Future<Response<dynamic>> delete(String path) {
    return _dio.delete(path);
  }

  Map<String, String> _idempotencyHeaders(String? idempotencyKey) {
    if (idempotencyKey == null) {
      return const {};
    }

    return {'Idempotency-Key': idempotencyKey};
  }
}
