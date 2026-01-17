import 'package:flutter/foundation.dart';

class AppConfig {
  // Static constant for base URL
  // Note: For Android Emulator use 'http://10.0.2.2:8080'
  // Note: For iOS Simulator use 'http://localhost:8080'
  // Note: For Web use 'http://localhost:8080' or relative if served from same origin
  
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }
}
