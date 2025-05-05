import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDio {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://57.128.166.138:2000/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // static final CustomDio _singleton = CustomDio._internal();

  CustomDio._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refreshToken');

            if (refreshToken != null) {
              try {
                final response = await Dio().post(
                  'http://57.128.166.138:2000/api/v1/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 &&
                    response.data['success'] == true) {
                  final newAccessToken = response.data['token'];
                  final newRefreshToken = response.data['refreshToken'];

                  await prefs.setString('accessToken', newAccessToken);
                  await prefs.setString('refreshToken', newRefreshToken);

                  // Retry the original request
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  final cloneReq = await _dio.request(
                    error.requestOptions.path,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                    options: Options(
                      method: error.requestOptions.method,
                      headers: error.requestOptions.headers,
                    ),
                  );

                  return handler.resolve(cloneReq);
                }
              } catch (e) {
                // Refresh failed — logout or show error
                prefs.clear(); // or navigate to login
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static Dio get instance => _dio;
}
