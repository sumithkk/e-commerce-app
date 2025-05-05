import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://57.128.166.138:2000/api/v1/auth';

  static Future<http.Response> register({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "password": password,
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "phoneNumber": phoneNumber,
      }),
    );

    print('🔐 [REGISTER] Status: ${response.statusCode}');
    print('📦 [REGISTER] Body: ${response.body}');

    return response;
  }

  static Future<http.Response> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('http://57.128.166.138:2000/api/v1/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
        "platform": "store-front",
      }),
    );

    print('🔐 [LOGIN] Status: \${response.statusCode}');
    print('📦 [LOGIN] Body: \${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['token']);
        await prefs.setString('refreshToken', data['refreshToken']);
        await prefs.setString('userId', data['customerId'].toString());
        await prefs.setString('cartId', data['cartId']);
        await prefs.setString('wishlistId', data['wishlistId']);

        print('✅ [LOGIN] Data saved to SharedPreferences');
      }
    }

    return response;
  }
}
