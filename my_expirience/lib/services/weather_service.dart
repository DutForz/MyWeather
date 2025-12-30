import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const BASE_URL_CURRENT = 'http://api.weatherapi.com/v1/current.json';
  static const BASE_URL_IP = 'http://ip-api.com/json/';
  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getCurrentWeather() async {
    try {
      return await _getCurrentWeatherByIP();
    } catch (e) {
      print('IP geolocation failed: $e');
      try {
        return await _getCurrentWeatherByLocation();
      } catch (locationError) {
        print('Geolocation failed: $locationError');
        return await _getWeatherForMoscow();
      }
    }
  }

  Future<Weather> _getCurrentWeatherByLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('Location permission denied');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 10),
    );

    final response = await http.get(
      Uri.parse(
        '$BASE_URL_CURRENT?key=$apiKey&q=${position.latitude},${position.longitude}&lang=ru',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Weather(
        cityName: data['location']['name'],
        temperature: data['current']['temp_c'].toDouble(),
        mainCondition: data['current']['condition']['text'],
      );
    } else {
      throw Exception(
        "Failed to load weather by location: ${response.statusCode}",
      );
    }
  }

  Future<Weather> _getCurrentWeatherByIP() async {
    final ipResponse = await http.get(Uri.parse(BASE_URL_IP));
    if (ipResponse.statusCode == 200) {
      final ipData = jsonDecode(ipResponse.body);

      if (ipData['status'] == 'success') {
        String city = ipData['city'] ?? 'Moscow';
        String country = ipData['country'] ?? 'Russia';
        final weatherResponse = await http.get(
          Uri.parse('$BASE_URL_CURRENT?key=$apiKey&q=$city,$country&lang=ru'),
        );

        if (weatherResponse.statusCode == 200) {
          final data = jsonDecode(weatherResponse.body);
          return Weather(
            cityName: data['location']['name'],
            temperature: data['current']['temp_c'].toDouble(),
            mainCondition: data['current']['condition']['text'],
          );
        }
      }
    }
    throw Exception('Failed to get weather by IP');
  }

  Future<Weather> _getWeatherForMoscow() async {
    final response = await http.get(
      Uri.parse('$BASE_URL_CURRENT?key=$apiKey&q=Moscow,Russia&lang=ru'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Weather(
        cityName: data['location']['name'],
        temperature: data['current']['temp_c'].toDouble(),
        mainCondition: data['current']['condition']['text'],
      );
    } else {
      throw Exception("Failed to load weather for Moscow");
    }
  }
}
