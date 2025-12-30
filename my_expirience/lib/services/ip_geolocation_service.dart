import 'dart:convert';
import 'package:http/http.dart' as http;

class IpGeolocationService {
  static const String API_URL = 'http://ip-api.com/json/';

  Future<Map<String, dynamic>> getLocation() async {
    final response = await http.get(Uri.parse(API_URL));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get location');
    }
  }
}
