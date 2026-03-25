import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const overridden = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (overridden.isNotEmpty) {
      return overridden;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000';
    }
  }
}
