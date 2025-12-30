// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'WeatherPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Массив страниц - пока только одна реальная страница
  final List<Widget> _pages = [const WeatherPage(), const Text("test")];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Погода'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_currentIndex == 0) {
                setState(() {
                  _pages[0] = const WeatherPage();
                });
              }
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Погода'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'заглушка',
          ),
        ],
      ),
    );
  }
}
