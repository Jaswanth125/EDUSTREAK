import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../models/study_assistant_models.dart';

// Backend URL Configuration:
// - Local development: http://localhost:8000 (or your computer's IP)
// - DigitalOcean cloud: http://YOUR_SERVER_IP:8000
// - With domain: https://yourdomain.com
// 
// To override, use: flutter run --dart-define=STUDY_ASSISTANT_URL=http://your-server:8000
// 
// For Android emulator, use: http://10.0.2.2:8000
// For iOS simulator, use: http://localhost:8000
// For physical device (local): Use your computer's IP (e.g., http://10.216.255.159:8000)
// For production (cloud): Use your DigitalOcean server IP
const String _defaultStudyAssistantUrl =
    String.fromEnvironment('STUDY_ASSISTANT_URL', defaultValue: 'http://localhost:8000');

class StudyAssistantException implements Exception {
  final String message;
  final int? statusCode;

  const StudyAssistantException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class StudyAssistantService {
  StudyAssistantService._internal();

  static final StudyAssistantService _instance = StudyAssistantService._internal();

  factory StudyAssistantService() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _defaultStudyAssistantUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<List<StudyDocument>> fetchDocuments() async {
    try {
      final response = await _dio.get('/documents/');
      final data = response.data;
      final docsList = data is Map<String, dynamic> ? data['documents'] : null;
      if (docsList is List) {
        return docsList
            .whereType<Map<String, dynamic>>()
            .map(StudyDocument.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to load documents');
    }
  }

  Future<int> fetchVectorStoreCount() async {
    try {
      final response = await _dio.get('/status/');
      final data = response.data;
      final value = data is Map<String, dynamic> ? data['vector_store_item_count'] : null;
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to fetch status');
    }
  }

  Future<List<String>> fetchTopics() async {
    try {
      final response = await _dio.get('/topics/');
      final data = response.data;
      final topics = data is Map<String, dynamic> ? data['topics'] : null;
      if (topics is List) {
        return topics.map((topic) => topic.toString()).toList();
      }
      return const [];
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to fetch topics');
    }
  }

  Future<StudySummaryResult> generateSummary({
    String? topic,
    List<String>? selectedDocuments,
  }) async {
    try {
      final response = await _dio.post(
        '/summary/',
        data: {
          'topic': topic?.trim() ?? '',
          'selected_documents': selectedDocuments ?? const [],
        },
      );
      return StudySummaryResult.fromJson(_castMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to generate summary');
    }
  }

  Future<StudyAnswerResult> askQuestion({
    required String question,
    List<String>? selectedDocuments,
  }) async {
    try {
      final response = await _dio.post(
        '/query/',
        data: {
          'question': question,
          'selected_documents': selectedDocuments ?? const [],
        },
      );
      return StudyAnswerResult.fromJson(_castMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to answer question');
    }
  }

  Future<StudyQuiz> generateQuiz({
    required String topic,
    required int numberOfQuestions,
    List<String>? selectedDocuments,
  }) async {
    try {
      final response = await _dio.post(
        '/quiz/interactive/',
        data: {
          'topic': topic,
          'num_questions': numberOfQuestions,
          'selected_documents': selectedDocuments ?? const [],
        },
      );
      return StudyQuiz.fromJson(_castMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to generate quiz');
    }
  }

  Future<String> chatWithTutor({
    required String message,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    try {
      final response = await _dio.post(
        '/chat/',
        data: {
          'message': message,
          'conversation_history': conversationHistory,
        },
      );
      final data = _castMap(response.data);
      return data['response'] as String? ?? '';
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to send chat message');
    }
  }

  Future<List<String>> uploadDocuments(List<PlatformFile> files) async {
    if (files.isEmpty) return const [];

    final responses = <String>[];
    try {
      for (final file in files) {
        final bytes = await _resolveBytes(file);
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: file.name,
          ),
        });
        final response = await _dio.post('/upload/', data: formData);
        final data = _castMap(response.data);
        responses.add(
          data['message'] as String? ?? 'Uploaded ${file.name}',
        );
      }
      return responses;
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Unable to upload documents');
    }
  }

  Map<String, dynamic> _castMap(dynamic data) {
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Uint8List> _resolveBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }

    // Fall back to readStream if available
    final stream = file.readStream;
    if (stream != null) {
      final buffer = BytesBuilder();
      await for (final chunk in stream) {
        buffer.add(chunk);
      }
      return buffer.toBytes();
    }

    throw const StudyAssistantException(
      'Unable to read file contents. Please try selecting the file again.',
    );
  }

  StudyAssistantException _mapError(
    DioException error, {
    required String fallback,
  }) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? message;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail != null) {
        message = detail.toString();
      }
    } else if (error.message != null) {
      message = error.message;
    }

    message ??= fallback;
    return StudyAssistantException(message, statusCode: status);
  }
}

