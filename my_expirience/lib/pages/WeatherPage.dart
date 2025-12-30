import 'package:flutter/material.dart';
import 'package:my_expirience/services/weather_service.dart';
import 'package:my_expirience/models/weather_model.dart';
import 'dart:math';
import 'dart:async';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with TickerProviderStateMixin {
  late final WeatherService _weatherService;
  Weather? _weather;
  bool _isLoading = true;
  String? _error;

  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _headerOpacity;
  late AnimationController _colorController;
  late Animation<Color?> _backgroundColor;
  late AnimationController _particleController;
  late Animation<double> _particleOpacity;

  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  double _tiltAngle = 0.0;
  bool _isHovering = false;
  bool _isPressed = false;

  late List<Snowflake> _snowflakes;
  late Timer _snowTimer;
  final int _snowflakeCount = 40;
  final double _snowflakeSizeFactor = 0.015;

  @override
  void initState() {
    super.initState();

    _weatherService = WeatherService("5f07aa8066a24358a0d14043252912");

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _colorController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _backgroundColor =
        ColorTween(
          begin: const Color(0xFF667eea),
          end: const Color(0xFF764ba2),
        ).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 2 * pi).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _isPressed) {
            _rotationController.repeat();
          }
        });

    _snowflakes = _generateSnowflakes();

    _fetchWeather();
  }

  List<Snowflake> _generateSnowflakes() {
    final random = Random();
    List<Snowflake> flakes = [];

    for (int i = 0; i < _snowflakeCount; i++) {
      flakes.add(
        Snowflake(
          x: random.nextDouble() * 100,
          y: random.nextDouble() * 100,
          size:
              _snowflakeSizeFactor +
              random.nextDouble() * _snowflakeSizeFactor * 0.5,
          speed: 0.5 + random.nextDouble() * 1.0,
          drift: -1.0 + random.nextDouble() * 2.0,
        ),
      );
    }

    return flakes;
  }

  void _updateSnowflakes() {
    setState(() {
      for (int i = 0; i < _snowflakes.length; i++) {
        var flake = _snowflakes[i];
        flake.y += flake.speed * 0.05;
        flake.x += flake.drift * 0.02;

        if (flake.y > 100) {
          flake.y = 0;
          flake.x = Random().nextDouble() * 100;
        }

        if (flake.x < 0 || flake.x > 100) {
          flake.x = 50;
        }
      }
    });
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getCurrentWeather();
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _weather = weather;
      });
      _iconController.forward();

      _snowTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _updateSnowflakes();
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

  void _startRotation() {
    if (!_isPressed) {
      _isPressed = true;
      _rotationController.repeat(period: const Duration(milliseconds: 800));
    }
  }

  void _stopRotation() {
    if (_isPressed) {
      _isPressed = false;
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    double tiltSensitivity = 0.02;
    _tiltAngle = details.delta.dx * tiltSensitivity;
    setState(() {});
  }

  void _handlePanEnd(DragEndDetails details) {
    _tiltAngle = 0.0;
    setState(() {});
  }

  void _handleHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });

    if (isHovering) {
      if (!_isPressed) {
        _rotationController.repeat(period: const Duration(seconds: 3));
      }
    } else if (!_isPressed) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _colorController.dispose();
    _particleController.dispose();
    _rotationController.dispose();
    _snowTimer.cancel();
    super.dispose();
  }

  Color _getColorByCondition(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('ясно') || condition.contains('clear')) {
      return const Color(0xFFFFD700);
    } else if (condition.contains('облачно') || condition.contains('cloud')) {
      return const Color(0xFFB0BEC5);
    } else if (condition.contains('дождь') || condition.contains('rain')) {
      return const Color(0xFF4FC3F7);
    } else if (condition.contains('снег') || condition.contains('snow')) {
      return const Color(0xFFE1F5FE);
    } else if (condition.contains('гроза') || condition.contains('thunder')) {
      return const Color(0xFFFFA726);
    }
    return const Color(0xFF78909C);
  }

  Widget _buildWeatherIcon(String condition) {
    Color color = _getColorByCondition(condition);
    double rotationValue = _rotationAnimation.value;
    double tiltValue = _tiltAngle;

    return MouseRegion(
      onHover: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: (_) => _startRotation(),
        onTapUp: (_) => _stopRotation(),
        onPanUpdate: _handlePanUpdate,
        onPanEnd: (_) => _handlePanEnd(DragEndDetails(velocity: Velocity.zero)),
        child: Transform.rotate(
          angle: rotationValue + tiltValue,
          child: ScaleTransition(
            scale: _iconScale,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(_isPressed ? 0.9 : 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(
                    _isHovering || _isPressed ? 0.8 : 0.4,
                  ),
                  width: _isPressed ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(_isPressed ? 0.6 : 0.4),
                    blurRadius: _isPressed ? 20 : 15,
                    spreadRadius: _isPressed ? 2 : 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getWeatherSymbol(condition),
                  style: TextStyle(
                    fontSize: 40,
                    color: color.withOpacity(_isPressed ? 0.5 : 0.3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getWeatherSymbol(String condition) {
    condition = condition.toLowerCase();

    if (condition.contains('ясно') || condition.contains('clear')) {
      return '☀';
    } else if (condition.contains('облачно') || condition.contains('cloud')) {
      return '☁';
    } else if (condition.contains('дождь') || condition.contains('rain')) {
      return '🌧';
    } else if (condition.contains('снег') || condition.contains('snow')) {
      return '❄';
    } else if (condition.contains('гроза') || condition.contains('thunder')) {
      return '⚡';
    }
    return '⛅';
  }

  Widget _buildWeatherParticles(String condition) {
    if (_isLoading || _error != null || _weather == null) return Container();

    condition = condition.toLowerCase();

    if (condition.contains('снег') || condition.contains('snow')) {
      return Positioned.fill(
        child: CustomPaint(
          size: Size.infinite,
          painter: SnowflakePainter(_snowflakes),
        ),
      );
    } else if (condition.contains('дождь') || condition.contains('rain')) {
      return Positioned.fill(
        child: CustomPaint(size: Size.infinite, painter: RaindropPainter()),
      );
    } else if (condition.contains('ясно') || condition.contains('clear')) {
      return Positioned.fill(
        child: CustomPaint(size: Size.infinite, painter: SunRayPainter()),
      );
    } else if (condition.contains('гроза') || condition.contains('thunder')) {
      return Positioned.fill(
        child: CustomPaint(size: Size.infinite, painter: LightningPainter()),
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _colorController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _backgroundColor.value ?? const Color(0xFF667eea),
                  (_backgroundColor.value ?? const Color(0xFF667eea))
                      .withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 1.0],
              ),
            ),
            child: Stack(
              children: [
                if (_weather != null)
                  _buildWeatherParticles(_weather!.mainCondition),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
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
                              FadeTransition(
                                opacity: _headerOpacity,
                                child: Text(
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
                              ),
                              const SizedBox(height: 20),
                              _buildWeatherIcon(_weather!.mainCondition),
                              const SizedBox(height: 20),
                              FadeTransition(
                                opacity: _headerOpacity,
                                child: Text(
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
                              ),
                              const SizedBox(height: 12),
                              FadeTransition(
                                opacity: _headerOpacity,
                                child: Container(
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
                              ),
                              const SizedBox(height: 20),
                            ],
                          )
                        : const Center(child: Text('Нет данных')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Snowflake {
  double x;
  double y;
  final double size;
  final double speed;
  final double drift;

  Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
  });
}

class SnowflakePainter extends CustomPainter {
  final List<Snowflake> snowflakes;

  SnowflakePainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var flake in snowflakes) {
      double x = size.width * (flake.x / 100);
      double y = size.height * (flake.y / 100);
      double flakeSize = size.width * flake.size;

      canvas.drawCircle(Offset(x, y), flakeSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RaindropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final random = Random();

    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      canvas.drawCircle(Offset(x, y), 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SunRayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * (pi / 180);
      double distance = radius * 0.7;

      double x = center.dx + cos(angle) * distance;
      double y = center.dy + sin(angle) * distance;

      canvas.drawCircle(Offset(x, y), 8.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LightningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final random = Random();

    for (int i = 0; i < 5; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      canvas.drawCircle(Offset(x, y), 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
