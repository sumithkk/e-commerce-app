// dio_client.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static final Dio dio =
      Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              // Attach access token to every request
              SharedPreferences.getInstance().then((prefs) {
                final token = prefs.getString('accessToken');
                if (token != null) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
                handler.next(options);
              });
            },
            onError: (DioError error, handler) async {
              if (error.response?.statusCode == 401) {
                final prefs = await SharedPreferences.getInstance();
                final refreshToken = prefs.getString('refreshToken');

                if (refreshToken != null) {
                  try {
                    final response = await Dio().post(
                      'http://16.171.147.184:2000/api/v1/auth/refresh',
                      data: {'refreshToken': refreshToken},
                    );

                    if (response.statusCode == 200 &&
                        response.data['accessToken'] != null) {
                      final newAccessToken = response.data['accessToken'];
                      await prefs.setString('accessToken', newAccessToken);

                      // Retry original request
                      final clonedRequest = await dio.request(
                        error.requestOptions.path,
                        options: Options(
                          method: error.requestOptions.method,
                          headers: {
                            ...error.requestOptions.headers,
                            'Authorization': 'Bearer $newAccessToken',
                          },
                        ),
                        data: error.requestOptions.data,
                        queryParameters: error.requestOptions.queryParameters,
                      );

                      return handler.resolve(clonedRequest);
                    }
                  } catch (e) {
                    // optional: log error or logout user
                  }
                }
              }

              return handler.next(error);
            },
          ),
        );
}
