import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper utility to resolve and format class names consistently across the app.
/// Prevents internal Firestore document IDs (e.g. 20-char hashes) from ever leaking into user-facing UI.
class ClassNameHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, String> _cache = {};

  /// Checks if a string looks like an internal Firestore random document ID (e.g. 15-35 alphanumeric chars without spaces).
  static bool isRawDocumentId(String val) {
    final trimmed = val.trim();
    if (trimmed.length < 15) return false;
    // If it contains spaces or common separators like dash or slash followed by single letter, it's likely a human name
    if (trimmed.contains(' ') || RegExp(r'^\d+[\s\-_/]+[A-Za-z]$').hasMatch(trimmed)) {
      return false;
    }
    // Check if it's alphanumeric with high entropy
    return RegExp(r'^[A-Za-z0-9_-]{15,35}$').hasMatch(trimmed);
  }

  /// Cleanly formats a class name string (e.g. "8A", "8-A", "Class 8 - A" -> "Class 8A").
  static String formatClassName(String val) => cleanFormattedName(val);
  static String cleanFormattedName(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return 'Class';

    // If it's a raw document ID, do NOT output it
    if (isRawDocumentId(trimmed)) {
      return 'Class (Assigned)';
    }

    // Check for common prefix patterns like "cls_8", "cls_8a", "cls_8_a", "sec_8_a", "class_8"
    final prefixPattern = RegExp(
      r'^(?:cls|class|sec|section)[_\-\s]*(\d+)[\s_\-\/]*([A-Za-z]?)$',
      caseSensitive: false,
    );
    final prefixMatch = prefixPattern.firstMatch(trimmed);
    if (prefixMatch != null) {
      final grade = prefixMatch.group(1) ?? '';
      final section = (prefixMatch.group(2) ?? '').toUpperCase();
      return section.isNotEmpty ? 'Class $grade$section' : 'Class $grade';
    }

    // Strip repeated leading "Class", "Grade", "Section", "Standard", "Std"
    while (true) {
      final stripped = trimmed.replaceFirst(
        RegExp(r'^(Class|Grade|Section|Standard|Std)[\s:\-_.]*', caseSensitive: false),
        '',
      ).trim();
      if (stripped == trimmed || stripped.isEmpty) break;
      trimmed = stripped;
    }

    if (trimmed.isEmpty) return 'Class';

    // "8A", "8-A", "8/A", "8_A" -> "Class 8A"
    final shortPattern = RegExp(r'^(\d+)\s*[\-_/\s]*([A-Za-z]?)$');
    final shortMatch = shortPattern.firstMatch(trimmed);
    if (shortMatch != null) {
      final grade = shortMatch.group(1) ?? '';
      final section = (shortMatch.group(2) ?? '').toUpperCase();
      return section.isNotEmpty ? 'Class $grade$section' : 'Class $grade';
    }

    // If it still contains "cls_" or "sec_", sanitize it completely
    if (RegExp(r'^(?:cls|sec)[_\-]', caseSensitive: false).hasMatch(trimmed)) {
      final cleaned = trimmed.replaceAll(RegExp(r'^(?:cls|sec)[_\-]+', caseSensitive: false), '');
      return cleanFormattedName(cleaned);
    }

    return 'Class $trimmed';
  }

  /// Fast synchronous formatting for synchronous UI widgets.
  /// Uses memory cache first. If uncached and is a raw ID, returns the safe fallback.
  static String formatClassNameSync(String classIdOrName, {String fallback = 'Class (Assigned)'}) {
    final trimmed = classIdOrName.trim();
    if (trimmed.isEmpty) return fallback;

    if (_cache.containsKey(trimmed)) {
      return _cache[trimmed]!;
    }

    if (isRawDocumentId(trimmed)) {
      return fallback;
    }

    return cleanFormattedName(trimmed);
  }

  /// Get class name for a class ID asynchronously with multi-tier lookup:
  /// 1. Memory Cache
  /// 2. Human-readable string check
  /// 3. Firestore collection 'classes/{classId}'
  /// 4. Firestore collection 'schools/{schoolId}/classes/{classId}'
  /// 5. Safe non-leaking fallback
  static Future<String> getClassName(String classId, {String? schoolId}) async {
    final trimmed = classId.trim();
    if (trimmed.isEmpty) return 'Class';

    // 1. Check cache first
    if (_cache.containsKey(trimmed)) {
      return _cache[trimmed]!;
    }

    // 2. Check if already a clean human-readable name (not an ID code like cls_8, sec_8, or raw hash)
    final isCodePattern = RegExp(r'^(?:cls|sec|class_id|grade_id)[_\-]', caseSensitive: false).hasMatch(trimmed);
    if (!isRawDocumentId(trimmed) && !isCodePattern && trimmed.length < 20 && !trimmed.contains('_')) {
      final formatted = cleanFormattedName(trimmed);
      _cache[trimmed] = formatted;
      return formatted;
    }

    // 3. Try global classes collection
    try {
      final classDoc = await _firestore.collection('classes').doc(trimmed).get();
      if (classDoc.exists) {
        final data = classDoc.data();
        final name = data?['name']?.toString().trim();
        final gradeName = data?['gradeName']?.toString().trim();
        final grade = (data?['grade'] ?? data?['gradeNumber'])?.toString().trim();
        final section = data?['section']?.toString().trim().toUpperCase();

        if (name != null && name.isNotEmpty && !isRawDocumentId(name) && !name.toLowerCase().startsWith('cls_')) {
          final formatted = cleanFormattedName(name);
          _cache[trimmed] = formatted;
          return formatted;
        }

        if (gradeName != null && gradeName.isNotEmpty && !gradeName.toLowerCase().startsWith('cls_')) {
          final formatted = cleanFormattedName(gradeName);
          _cache[trimmed] = formatted;
          return formatted;
        }

        if (grade != null && grade.isNotEmpty) {
          final formatted = (section != null && section.isNotEmpty)
              ? 'Class $grade$section'
              : 'Class $grade';
          _cache[trimmed] = formatted;
          return formatted;
        }
      }
    } catch (_) {}

    // 4. Try school-scoped classes collection if schoolId is provided
    if (schoolId != null && schoolId.isNotEmpty) {
      try {
        final schoolClassDoc = await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('classes')
            .doc(trimmed)
            .get();

        if (schoolClassDoc.exists) {
          final data = schoolClassDoc.data();
          final name = data?['name']?.toString().trim();
          final grade = data?['grade']?.toString().trim();
          final section = data?['section']?.toString().trim().toUpperCase();

          if (name != null && name.isNotEmpty && !isRawDocumentId(name)) {
            final formatted = cleanFormattedName(name);
            _cache[trimmed] = formatted;
            return formatted;
          }

          if (grade != null && grade.isNotEmpty) {
            final formatted = (section != null && section.isNotEmpty)
                ? 'Class $grade$section'
                : 'Class $grade';
            _cache[trimmed] = formatted;
            return formatted;
          }
        }
      } catch (_) {}
    }

    // 5. Safe non-leaking fallback: NEVER return a raw document ID
    final cleaned = cleanFormattedName(trimmed);
    final safeFallback = isRawDocumentId(cleaned) ? 'Class (Assigned)' : cleaned;
    _cache[trimmed] = safeFallback;
    return safeFallback;
  }

  /// Get class names for multiple class IDs in batch
  static Future<Map<String, String>> getClassNames(
    List<String> classIds, {
    String? schoolId,
  }) async {
    final Map<String, String> resultMap = {};
    final List<String> toFetch = [];

    for (final id in classIds) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) continue;

      if (_cache.containsKey(trimmed)) {
        resultMap[trimmed] = _cache[trimmed]!;
      } else if (!isRawDocumentId(trimmed) && trimmed.length < 20) {
        final formatted = cleanFormattedName(trimmed);
        _cache[trimmed] = formatted;
        resultMap[trimmed] = formatted;
      } else {
        toFetch.add(trimmed);
      }
    }

    if (toFetch.isEmpty) {
      return resultMap;
    }

    // Fetch remaining in parallel
    final futures = toFetch.map((id) async {
      final resolved = await getClassName(id, schoolId: schoolId);
      return MapEntry(id, resolved);
    });

    final resolvedEntries = await Future.wait(futures);
    for (final entry in resolvedEntries) {
      resultMap[entry.key] = entry.value;
    }

    return resultMap;
  }

  /// Clear the entire cache
  static void clearCache() {
    _cache.clear();
  }

  /// Clear cache for a specific class
  static void clearCacheForClass(String classId) {
    _cache.remove(classId.trim());
  }

  /// Preload cache with known mapping
  static void setCachedName(String classId, String displayName) {
    _cache[classId.trim()] = cleanFormattedName(displayName);
  }
}


