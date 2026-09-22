import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // --- DEVELOPMENT TARGET CONFIGURATION ---
  // Change this to false when testing on a physical device.
  // Change this to true when testing on an Android Emulator.
  static const bool useEmulator = true;

  // --- PHYSICAL DEVICE CONFIGURATION ---
  // When useEmulator is false, this IP address is used.
  // Find this by running `ipconfig` (Windows) or `ifconfig` (Mac/Linux).
  // Look for IPv4 Address under your active network adapter (e.g., Wi-Fi).
  // Example: '192.168.1.10'
  static const String physicalDeviceLanIp = '192.168.1.X';

  // Backend Port (Make sure this matches the PORT in your backend .env file)
  static const int port = 5000;

  static String get baseUrl {
    // If running on Windows desktop or Web, use localhost, otherwise use 10.0.2.2 for Android emulator
    bool isWindowsDesktop = false;
    try {
      if (const String.fromEnvironment('dart.library.io') == 'true') {
        isWindowsDesktop = true;
      }
    } catch (_) {}

    if (useEmulator) {
      if (kIsWeb || isWindowsDesktop) {
        return 'http://127.0.0.1:$port/api';
      }
      return 'http://10.0.2.2:$port/api';
    } else {
      return 'http://$physicalDeviceLanIp:$port/api';
    }
  }
}
