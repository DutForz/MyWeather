import 'package:flutter/material.dart';
import 'package:my_expirience/services/weather_service.dart';
import 'package:my_expirience/models/weather_model.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late final WeatherService _weatherService;
  Weather? _weather;
  bool _isLoading = true;
  String? _error;

  static const Map<String, Map<String, dynamic>> _weatherConditions = {
    'clear': {
      'symbol': '☀',
      'bgColor': Color(0xFFFFD700),
      'symbolColor': Color(0xFF8B7500),
    },
    'ясно': {
      'symbol': '☀',
      'bgColor': Color(0xFFFFD700),
      'symbolColor': Color(0xFF8B7500),
    },
    'cloud': {
      'symbol': '☁',
      'bgColor': Color(0xFFB0BEC5),
      'symbolColor': Color(0xFF455A64),
    },
    'облачно': {
      'symbol': '☁',
      'bgColor': Color(0xFFB0BEC5),
      'symbolColor': Color(0xFF455A64),
    },
    'rain': {
      'symbol': '🌧',
      'bgColor': Color(0xFF4FC3F7),
      'symbolColor': Color(0xFF01579B),
    },
    'дождь': {
      'symbol': '🌧',
      'bgColor': Color(0xFF4FC3F7),
      'symbolColor': Color(0xFF01579B),
    },
    'snow': {
      'symbol': '❄',
      'bgColor': Color(0xFFE1F5FE),
      'symbolColor': Color.fromARGB(255, 14, 69, 110),
    },
    'снег': {
      'symbol': '❄',
      'bgColor': Color(0xFFE1F5FE),
      'symbolColor': Color.fromARGB(255, 8, 50, 82),
    },
    'thunder': {
      'symbol': '⚡',
      'bgColor': Color(0xFFFFA726),
      'symbolColor': Color(0xFFE65100),
    },
    'гроза': {
      'symbol': '⚡',
      'bgColor': Color(0xFFFFA726),
      'symbolColor': Color(0xFFE65100),
    },
    'default': {
      'symbol': '⛅',
      'bgColor': Color(0xFF78909C),
      'symbolColor': Color(0xFF263238),
    },
  };

  @override
  void initState() {
    super.initState();
    _weatherService = WeatherService("5f07aa8066a24358a0d14043252912");
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getCurrentWeather();
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить погоду';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getWeatherData(String condition) {
    final normalizedCondition = condition.toLowerCase();

    for (final entry in _weatherConditions.entries) {
      if (normalizedCondition.contains(entry.key)) {
        return entry.value;
      }
    }

    return _weatherConditions['default']!;
  }

  Widget _buildWeatherIcon(String condition) {
    final weatherData = _getWeatherData(condition);
    final bgColor = weatherData['bgColor'] as Color;
    final symbolColor = weatherData['symbolColor'] as Color;

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: bgColor.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          weatherData['symbol'] as String,
          style: TextStyle(
            fontSize: 40,
            color: symbolColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 80,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _fetchWeather,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Обновить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _weather != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weather!.cityName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildWeatherIcon(_weather!.mainCondition),
                      const SizedBox(height: 20),
                      Text(
                        '${_weather!.temperature.round()}°',
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _weather!.mainCondition,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: Text('Нет данных')),
          ),
        ),
      ),
    );
  }
}
