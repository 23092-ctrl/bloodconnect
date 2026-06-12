import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(dio),
      PrettyDioLogger(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = LocalStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = LocalStorage.refreshToken;
        if (refreshToken != null) {
          final response = await dio.post(
            ApiEndpoints.refresh,
            options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
          );
          final data = response.data['data'];
          await LocalStorage.saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
          err.requestOptions.headers['Authorization'] =
              'Bearer ${data['accessToken']}';
          final retryResponse = await dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        await LocalStorage.clear();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}
