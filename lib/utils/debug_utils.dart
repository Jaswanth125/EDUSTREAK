import 'package:flutter/foundation.dart';

/// Safe debug print function that handles null values
/// Flutter web's DebugService cannot send null values through method channels
/// This function ensures all values are converted to strings before printing
void safeDebugPrint(Object? object, {String? prefix}) {
  if (kDebugMode) {
    try {
      // Convert to string safely, handling null values
      final message = object?.toString() ?? 'null';
      final output = prefix != null ? '$prefix: $message' : message;
      debugPrint(output);
    } catch (e) {
      // If even toString fails, print a safe message
      debugPrint('Debug print error: Unable to convert value to string');
    }
  }
}

/// Safe error logging that handles null values in error messages
void safeErrorPrint(String message, [Object? error]) {
  if (kDebugMode) {
    try {
      final errorStr = error?.toString() ?? 'Unknown error';
      debugPrint('$message: $errorStr');
    } catch (e) {
      debugPrint('$message: [Error details unavailable]');
    }
  }
}
