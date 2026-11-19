class TopicModel {
  final String id;
  final String title;
  final int order;
  final String? description;
  final int estimatedMinutes;
  final bool isCompleted;

  const TopicModel({
    required this.id,
    required this.title,
    required this.order,
    this.description,
    this.estimatedMinutes = 20,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'order': order,
    'description': description,
    'estimatedMinutes': estimatedMinutes,
    'isCompleted': isCompleted,
  };

  factory TopicModel.fromMap(Map<String, dynamic> map) => TopicModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    order: (map['order'] as num?)?.toInt() ?? 0,
    description: map['description'],
    estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 20,
    isCompleted: map['isCompleted'] ?? false,
  );
}

class ChapterModel {
  final String id;
  final String title;
  final int chapterNumber;
  final List<TopicModel> topics;
  final double progress; // 0.0 to 1.0

  const ChapterModel({
    required this.id,
    required this.title,
    required this.chapterNumber,
    this.topics = const [],
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'chapterNumber': chapterNumber,
    'topics': topics.map((t) => t.toMap()).toList(),
    'progress': progress,
  };

  factory ChapterModel.fromMap(Map<String, dynamic> map) => ChapterModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    chapterNumber: (map['chapterNumber'] as num?)?.toInt() ?? 1,
    topics: (map['topics'] as List<dynamic>?)
            ?.map((e) => TopicModel.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
  );
}

class SubjectCurriculumModel {
  final String id;
  final String name;
  final String code;
  final int colorValue; // For rendering subject color
  final List<ChapterModel> chapters;
  final double completionPercentage; // 0.0 to 100.0

  const SubjectCurriculumModel({
    required this.id,
    required this.name,
    required this.code,
    required this.colorValue,
    this.chapters = const [],
    this.completionPercentage = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'code': code,
    'colorValue': colorValue,
    'chapters': chapters.map((c) => c.toMap()).toList(),
    'completionPercentage': completionPercentage,
  };

  factory SubjectCurriculumModel.fromMap(Map<String, dynamic> map) =>
      SubjectCurriculumModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        code: map['code'] ?? '',
        colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF7C6FFF,
        chapters: (map['chapters'] as List<dynamic>?)
                ?.map((e) => ChapterModel.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        completionPercentage:
            (map['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      );
}

class SectionModel {
  final String id;
  final String name; // 'A', 'B', 'C'
  final String classId;
  final String? classTeacherId;
  final String? classTeacherName;
  final int totalStudents;

  const SectionModel({
    required this.id,
    required this.name,
    required this.classId,
    this.classTeacherId,
    this.classTeacherName,
    this.totalStudents = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'classId': classId,
    'classTeacherId': classTeacherId,
    'classTeacherName': classTeacherName,
    'totalStudents': totalStudents,
  };

  factory SectionModel.fromMap(Map<String, dynamic> map) => SectionModel(
    id: map['id'] ?? '',
    name: map['name'] ?? 'A',
    classId: map['classId'] ?? '',
    classTeacherId: map['classTeacherId'],
    classTeacherName: map['classTeacherName'],
    totalStudents: (map['totalStudents'] as num?)?.toInt() ?? 0,
  );
}

class GradeClassModel {
  final String id;
  final int gradeNumber; // 8 for Class 8
  final String gradeName; // 'Class 8'
  final List<SectionModel> sections;
  final List<SubjectCurriculumModel> subjects;

  const GradeClassModel({
    required this.id,
    required this.gradeNumber,
    required this.gradeName,
    this.sections = const [],
    this.subjects = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'gradeNumber': gradeNumber,
    'gradeName': gradeName,
    'sections': sections.map((s) => s.toMap()).toList(),
    'subjects': subjects.map((s) => s.toMap()).toList(),
  };

  factory GradeClassModel.fromMap(Map<String, dynamic> map) => GradeClassModel(
    id: map['id'] ?? '',
    gradeNumber: (map['gradeNumber'] as num?)?.toInt() ?? 8,
    gradeName: map['gradeName'] ?? 'Class 8',
    sections: (map['sections'] as List<dynamic>?)
            ?.map((e) => SectionModel.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    subjects: (map['subjects'] as List<dynamic>?)
            ?.map((e) =>
                SubjectCurriculumModel.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class AcademicYearModel {
  final String id;
  final String label; // e.g. "2026-2027"
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final List<GradeClassModel> classes;

  const AcademicYearModel({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    this.isCurrent = true,
    this.classes = const [],
  });
}

class CurriculumTemplateModel {
  final String id;
  final String name; // "AP State Board", "CBSE Central", "Private Autonomous"
  final String boardCode;
  final String description;
  final int adoptedSchoolsCount;
  final bool isActive;
  final List<SubjectCurriculumModel> standardSubjects;

  const CurriculumTemplateModel({
    required this.id,
    required this.name,
    required this.boardCode,
    required this.description,
    required this.adoptedSchoolsCount,
    this.isActive = true,
    this.standardSubjects = const [],
  });
}
