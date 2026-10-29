import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper utility to get class names consistently across the app
class ClassNameHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, String> _cache = {};

  /// Get class name for a class ID
  /// Returns formatted name like "Class 9" or the stored name
  static Future<String> getClassName(String classId) async {
    // Check cache first
    if (_cache.containsKey(classId)) {
      return _cache[classId]!;
    }

    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      
      if (classDoc.exists) {
        final data = classDoc.data();
        final className = data?['name'] ?? 'Class $classId';
        _cache[classId] = className;
        return className;
      } else {
        // If class doesn't exist, return formatted ID
        final fallback = 'Class $classId';
        _cache[classId] = fallback;
        return fallback;
      }
    } catch (e) {
      // On error, return formatted ID
      final fallback = 'Class $classId';
      _cache[classId] = fallback;
      return fallback;
    }
  }

  /// Get class names for multiple class IDs
  static Future<Map<String, String>> getClassNames(List<String> classIds) async {
    final Map<String, String> classNamesMap = {};
    
    for (final classId in classIds) {
      // Check cache first
      if (_cache.containsKey(classId)) {
        classNamesMap[classId] = _cache[classId]!;
      } else {
        try {
          final classDoc = await _firestore.collection('classes').doc(classId).get();
          if (classDoc.exists) {
            final data = classDoc.data();
            final className = data?['name'] ?? 'Class $classId';
            _cache[classId] = className;
            classNamesMap[classId] = className;
          } else {
            final fallback = 'Class $classId';
            _cache[classId] = fallback;
            classNamesMap[classId] = fallback;
          }
        } catch (e) {
          final fallback = 'Class $classId';
          _cache[classId] = fallback;
          classNamesMap[classId] = fallback;
        }
      }
    }
    
    return classNamesMap;
  }

  /// Clear the cache (useful when class names are updated)
  static void clearCache() {
    _cache.clear();
  }

  /// Clear cache for a specific class
  static void clearCacheForClass(String classId) {
    _cache.remove(classId);
  }
}

