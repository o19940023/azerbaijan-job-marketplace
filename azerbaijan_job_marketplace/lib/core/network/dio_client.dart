import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  DioClient(this._secureStorage, this._logger) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}/${AppConstants.apiVersion}',
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    final token = await _secureStorage.read(key: AppConstants.authTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.d(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  void _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _logger.e(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    handler.next(err);
  }
}
