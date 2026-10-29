class StudyDocument {
  final String filename;
  final int chunkCount;
  final DateTime? uploadedAt;

  const StudyDocument({
    required this.filename,
    required this.chunkCount,
    this.uploadedAt,
  });

  factory StudyDocument.fromJson(Map<String, dynamic> json) {
    DateTime? uploadedAt;
    final uploadedRaw = json['uploaded_at'];
    if (uploadedRaw is String && uploadedRaw.isNotEmpty) {
      uploadedAt = DateTime.tryParse(uploadedRaw);
    }

    return StudyDocument(
      filename: json['filename'] as String? ?? 'Untitled Document',
      chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
      uploadedAt: uploadedAt,
    );
  }
}

class StudySummaryResult {
  final String topic;
  final String summary;

  const StudySummaryResult({
    required this.topic,
    required this.summary,
  });

  factory StudySummaryResult.fromJson(Map<String, dynamic> json) {
    return StudySummaryResult(
      topic: json['topic'] as String? ?? 'Summary',
      summary: json['summary'] as String? ?? '',
    );
  }
}

class StudyAnswerResult {
  final String answer;
  final String context;
  final double score;

  const StudyAnswerResult({
    required this.answer,
    required this.context,
    required this.score,
  });

  factory StudyAnswerResult.fromJson(Map<String, dynamic> json) {
    final scoreValue = json['score'];
    return StudyAnswerResult(
      answer: json['answer'] as String? ?? '',
      context: json['context'] as String? ?? '',
      score: scoreValue is num ? scoreValue.toDouble() : 0,
    );
  }
}

class StudyQuizQuestion {
  final int id;
  final String question;
  final Map<String, String> options;
  final String correctAnswer;
  final String explanation;

  const StudyQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory StudyQuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <String, String>{};
    if (rawOptions is Map<String, dynamic>) {
      rawOptions.forEach((key, value) {
        options[key] = value?.toString() ?? '';
      });
    }

    return StudyQuizQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: json['question'] as String? ?? '',
      options: options,
      correctAnswer: json['correct_answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class StudyQuiz {
  final String topic;
  final List<StudyQuizQuestion> questions;

  const StudyQuiz({
    required this.topic,
    required this.questions,
  });

  factory StudyQuiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = <StudyQuizQuestion>[];
    if (rawQuestions is List) {
      for (final item in rawQuestions) {
        if (item is Map<String, dynamic>) {
          questions.add(StudyQuizQuestion.fromJson(item));
        }
      }
    }

    return StudyQuiz(
      topic: json['topic'] as String? ?? 'Quiz',
      questions: questions,
    );
  }
}

