import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamil Nadu Scholarship Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FoundationScreen(),
    );
  }
}

class FoundationScreen extends StatefulWidget {
  const FoundationScreen({super.key});

  @override
  State<FoundationScreen> createState() => _FoundationScreenState();
}

class _FoundationScreenState extends State<FoundationScreen> {
  String _backendStatus = "Checking backend...";

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    final response = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          _backendStatus = "Backend Connected";
        } else {
          _backendStatus = "Backend Unavailable";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamil Nadu Scholarship Finder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Tamil Nadu Scholarship Finder',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Find scholarships available for you',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _backendStatus == "Backend Connected" 
                    ? Colors.green.shade100 
                    : (_backendStatus == "Checking backend..." ? Colors.yellow.shade100 : Colors.red.shade100),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _backendStatus,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _backendStatus == "Backend Connected" 
                      ? Colors.green.shade900 
                      : (_backendStatus == "Checking backend..." ? Colors.orange.shade900 : Colors.red.shade900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
