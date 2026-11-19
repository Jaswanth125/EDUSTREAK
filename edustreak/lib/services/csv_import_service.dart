import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/roster_student_model.dart';
import '../models/roster_teacher_model.dart';
import 'audit_service.dart';

class CsvStudentRow {
  final int rowIndex;
  final String rollNumber;
  final String admissionNumber;
  final String studentName;
  final String grade; // e.g. "8" or "10"
  final String section; // e.g. "A" or "B"
  final String academicYear; // e.g. "2026-2027"
  final String parentName;
  final String parentEmail;
  final String parentPhone;
  final String verificationPin;
  final bool isValid;
  final String? error;

  const CsvStudentRow({
    required this.rowIndex,
    required this.rollNumber,
    required this.admissionNumber,
    required this.studentName,
    required this.grade,
    required this.section,
    this.academicYear = '2026-2027',
    this.parentName = '',
    this.parentEmail = '',
    this.parentPhone = '',
    this.verificationPin = '1234',
    this.isValid = true,
    this.error,
  });

  String get classLabel => 'Class $grade-$section';
}

class CsvValidationResult {
  final int totalRows;
  final List<CsvStudentRow> validRows;
  final List<CsvStudentRow> invalidRows;
  final List<String> globalErrors;

  const CsvValidationResult({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    this.globalErrors = const [],
  });

  bool get hasErrors => invalidRows.isNotEmpty || globalErrors.isNotEmpty;
}

class CsvTeacherRow {
  final int rowIndex;
  final String teacherName;
  final String employeeId;
  final String email;
  final String phone;
  final List<String> assignedSubjects;
  final List<String> assignedClasses;
  final String academicYear;
  final String verificationPin;
  final bool isValid;
  final String? error;

  const CsvTeacherRow({
    required this.rowIndex,
    required this.teacherName,
    required this.employeeId,
    required this.email,
    this.phone = '',
    required this.assignedSubjects,
    required this.assignedClasses,
    this.academicYear = '2026-2027',
    this.verificationPin = '5678',
    this.isValid = true,
    this.error,
  });
}

class CsvTeacherValidationResult {
  final int totalRows;
  final List<CsvTeacherRow> validRows;
  final List<CsvTeacherRow> invalidRows;
  final List<String> globalErrors;

  const CsvTeacherValidationResult({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    this.globalErrors = const [],
  });

  bool get hasErrors => invalidRows.isNotEmpty || globalErrors.isNotEmpty;
}

class CsvImportSummary {
  final int totalProcessed;
  final int studentsCreated;
  final int teachersCreated;
  final int parentsCreated;
  final List<String> errors;

  const CsvImportSummary({
    required this.totalProcessed,
    this.studentsCreated = 0,
    this.teachersCreated = 0,
    this.parentsCreated = 0,
    this.errors = const [],
  });
}

class CsvImportService {
  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CsvImportService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  static String generateVerificationPin() {
    final rand = Random.secure();
    return (1000 + rand.nextInt(9000)).toString();
  }

  /// Template generator for Students CSV
  static String getStudentCsvTemplate() {
    return '''student_name,roll_number,admission_number,class,section,academic_year,parent_name,parent_email,parent_phone
Ravi Kumar,101,ADM001,8,A,2026-2027,Suresh Kumar,suresh@example.com,9876543210
Priya Sharma,102,ADM002,8,A,2026-2027,Rajesh Sharma,rajesh@example.com,9876543211
Ananya Reddy,103,ADM003,9,B,2026-2027,Venkat Reddy,venkat@example.com,9876543212''';
  }

  /// Template generator for Teachers CSV
  static String getTeacherCsvTemplate() {
    return '''teacher_name,employee_id,email,phone,assigned_subjects,assigned_classes,academic_year
Dr. Sarah Jenkins,EMP014,sarah.jenkins@edustreak.com,9876543220,Mathematics;Physics,Class 8-A;Class 9-B,2026-2027
Mr. David Smith,EMP015,david.smith@edustreak.com,9876543221,Biology;General Science,Class 7-A;Class 8-B,2026-2027
Ms. Kavita Rao,EMP016,kavita.rao@edustreak.com,9876543222,English;Social Studies,Class 6-A;Class 6-B,2026-2027''';
  }

  /// Parse and validate Student CSV raw string
  Future<CsvValidationResult> validateCsv({
    required String csvContent,
    required String schoolId,
  }) async {
    final lines = csvContent
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const CsvValidationResult(
        totalRows: 0,
        validRows: [],
        invalidRows: [],
        globalErrors: ['The CSV file is completely empty.'],
      );
    }

    // 1. Header parsing & validation
    final headerLine = lines.first.toLowerCase();
    final headers = _parseCsvLine(headerLine);

    int idxRoll = _findHeaderIndex(headers, ['roll_number', 'roll_no', 'rollno', 'roll']);
    int idxAdm = _findHeaderIndex(headers, ['admission_number', 'admission_no', 'adm_no', 'admissionno']);
    int idxName = _findHeaderIndex(headers, ['student_name', 'name', 'studentname', 'fullname', 'full_name']);
    int idxClass = _findHeaderIndex(headers, ['class', 'grade', 'standard']);
    int idxSection = _findHeaderIndex(headers, ['section', 'sec']);
    int idxYear = _findHeaderIndex(headers, ['academic_year', 'year', 'session']);
    int idxParentName = _findHeaderIndex(headers, ['parent_name', 'parent', 'guardian_name', 'father_name']);
    int idxParentEmail = _findHeaderIndex(headers, ['parent_email', 'email', 'parentemail']);
    int idxParentPhone = _findHeaderIndex(headers, ['parent_phone', 'phone', 'mobile', 'parent_mobile']);

    // Fallback: if admission_number not explicitly found, use roll index
    if (idxRoll == -1 && idxAdm != -1) idxRoll = idxAdm;
    if (idxAdm == -1 && idxRoll != -1) idxAdm = idxRoll;

    final missingColumns = <String>[];
    if (idxRoll == -1) missingColumns.add('roll_number');
    if (idxName == -1) missingColumns.add('student_name');
    if (idxClass == -1) missingColumns.add('class');
    if (idxSection == -1) missingColumns.add('section');

    if (missingColumns.isNotEmpty) {
      return CsvValidationResult(
        totalRows: lines.length - 1,
        validRows: [],
        invalidRows: [],
        globalErrors: [
          'Missing required columns: ${missingColumns.join(', ')}. Expected at least: student_name, roll_number, class, section'
        ],
      );
    }

    // 2. Fetch existing roll numbers in this school to detect cross-database collisions
    final existingRollsInSchool = <String>{};
    try {
      final rosterQuery = await _firestore
          .collection('roster_students')
          .where('schoolId', isEqualTo: schoolId)
          .get();
      for (var doc in rosterQuery.docs) {
        final roll = doc.data()['rollNumber']?.toString().trim();
        if (roll != null && roll.isNotEmpty) {
          existingRollsInSchool.add(roll);
        }
      }

      final usersQuery = await _firestore
          .collection('users')
          .where('schoolId', isEqualTo: schoolId)
          .where('role', isEqualTo: 'student')
          .get();
      for (var doc in usersQuery.docs) {
        final roll = doc.data()['rollNumber']?.toString().trim();
        if (roll != null && roll.isNotEmpty) {
          existingRollsInSchool.add(roll);
        }
      }
    } catch (_) {}

    // 3. Row by row validation
    final seenRollsInFile = <String>{};
    final validRows = <CsvStudentRow>[];
    final invalidRows = <CsvStudentRow>[];

    for (int i = 1; i < lines.length; i++) {
      final rawLine = lines[i];
      final values = _parseCsvLine(rawLine);

      final roll = idxRoll < values.length ? values[idxRoll].trim() : '';
      final adm = idxAdm < values.length && idxAdm != -1 ? values[idxAdm].trim() : roll;
      final name = idxName < values.length ? values[idxName].trim() : '';
      final grade = idxClass < values.length ? values[idxClass].trim().replaceAll(RegExp(r'[^0-9]'), '') : '';
      final section = idxSection < values.length ? values[idxSection].trim().toUpperCase() : '';
      final year = idxYear != -1 && idxYear < values.length ? values[idxYear].trim() : '2026-2027';
      final parentName = idxParentName != -1 && idxParentName < values.length ? values[idxParentName].trim() : '';
      final parentEmail = idxParentEmail != -1 && idxParentEmail < values.length ? values[idxParentEmail].trim() : '';
      final parentPhone = idxParentPhone != -1 && idxParentPhone < values.length ? values[idxParentPhone].trim() : '';

      String? rowError;
      if (roll.isEmpty) {
        rowError = 'Missing roll number';
      } else if (name.isEmpty) {
        rowError = 'Missing student name';
      } else if (grade.isEmpty) {
        rowError = 'Missing class/grade';
      } else if (section.isEmpty) {
        rowError = 'Missing section';
      } else if (seenRollsInFile.contains(roll)) {
        rowError = 'Duplicate roll number in this CSV file ($roll)';
      } else if (existingRollsInSchool.contains(roll)) {
        rowError = 'Roll number $roll already exists in this school';
      }

      final parsedRow = CsvStudentRow(
        rowIndex: i + 1,
        rollNumber: roll,
        admissionNumber: adm.isNotEmpty ? adm : roll,
        studentName: name,
        grade: grade,
        section: section,
        academicYear: year.isNotEmpty ? year : '2026-2027',
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
        verificationPin: generateVerificationPin(),
        isValid: rowError == null,
        error: rowError,
      );

      if (rowError == null) {
        seenRollsInFile.add(roll);
        validRows.add(parsedRow);
      } else {
        invalidRows.add(parsedRow);
      }
    }

    return CsvValidationResult(
      totalRows: lines.length - 1,
      validRows: validRows,
      invalidRows: invalidRows,
    );
  }

  /// Batch provision validated student roster records into Firestore
  Future<CsvImportSummary> executeImport({
    required String schoolId,
    required String schoolCode,
    required List<CsvStudentRow> rows,
  }) async {
    int studentsCreated = 0;
    int parentsCreated = 0;
    final errors = <String>[];

    final batch = _firestore.batch();

    for (final row in rows) {
      if (!row.isValid) continue;

      try {
        final cleanCode = schoolCode.trim().toUpperCase();
        final rosterDocRef = _firestore
            .collection('roster_students')
            .doc('roster_std_${cleanCode}_${row.rollNumber}');

        final classId = 'class_${cleanCode.toLowerCase()}_${row.grade}_${row.section.toLowerCase()}';

        final rosterModel = RosterStudentModel(
          id: rosterDocRef.id,
          schoolId: schoolId,
          schoolCode: cleanCode,
          studentName: row.studentName,
          rollNumber: row.rollNumber,
          admissionNumber: row.admissionNumber,
          grade: row.grade,
          section: row.section,
          classId: classId,
          academicYear: row.academicYear,
          email: row.parentEmail.isNotEmpty ? row.parentEmail : null,
          parentName: row.parentName.isNotEmpty ? row.parentName : null,
          parentPhone: row.parentPhone.isNotEmpty ? row.parentPhone : null,
          parentEmail: row.parentEmail.isNotEmpty ? row.parentEmail : null,
          verificationPin: row.verificationPin,
          status: 'not_registered',
          createdAt: DateTime.now(),
        );

        batch.set(rosterDocRef, rosterModel.toMap());

        // Also add an unclaimed user document so existing student listing/queries see the student immediately
        final userDocRef = _firestore.collection('users').doc('std_pre_${cleanCode}_${row.rollNumber}');
        final studentEmail = 'std_${cleanCode.toLowerCase()}_${row.rollNumber.toLowerCase()}@student.edustreak.internal';
        
        final userModel = UserModel(
          id: userDocRef.id,
          name: row.studentName,
          email: studentEmail,
          role: 'student',
          classId: classId,
          schoolId: schoolId,
          schoolCode: cleanCode,
          rollNumber: row.rollNumber,
          admissionNumber: row.admissionNumber,
          grade: row.grade,
          section: row.section,
          academicYear: row.academicYear,
          isActive: false, // inactive until student claims and sets password
          status: 'not_registered',
          streak: 0,
          streakCount: 0,
          highestStreak: 0,
          xp: 0,
          level: 1,
        );

        batch.set(userDocRef, userModel.toMap(), SetOptions(merge: true));
        studentsCreated++;
      } catch (e) {
        errors.add('Failed on row ${row.rowIndex} (${row.studentName}): $e');
      }
    }

    await batch.commit();

    // Persist batch import record to /import_batches
    final batchRecordRef = _firestore.collection('import_batches').doc();
    await batchRecordRef.set({
      'batchId': batchRecordRef.id,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'type': 'students',
      'totalProcessed': rows.length,
      'studentsCreated': studentsCreated,
      'errors': errors,
      'status': errors.isEmpty ? 'completed' : 'completed_with_errors',
      'importedAt': FieldValue.serverTimestamp(),
    });

    // Update school total students count
    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'totalStudents': FieldValue.increment(studentsCreated),
      });
    } catch (_) {}

    // Audit log
    final auditService = AuditService();
    await auditService.logAction(
      action: 'STUDENTS_CSV_ROSTER_IMPORTED',
      targetType: 'school',
      targetId: schoolId,
      details: {
        'batchId': batchRecordRef.id,
        'schoolCode': schoolCode,
        'studentsCreated': studentsCreated,
        'errorCount': errors.length,
      },
    );

    return CsvImportSummary(
      totalProcessed: rows.length,
      studentsCreated: studentsCreated,
      parentsCreated: parentsCreated,
      errors: errors,
    );
  }

  /// Parse and validate Teacher CSV raw string
  Future<CsvTeacherValidationResult> validateTeacherCsv({
    required String csvContent,
    required String schoolId,
  }) async {
    final lines = csvContent
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const CsvTeacherValidationResult(
        totalRows: 0,
        validRows: [],
        invalidRows: [],
        globalErrors: ['The Teacher CSV file is completely empty.'],
      );
    }

    final headerLine = lines.first.toLowerCase();
    final headers = _parseCsvLine(headerLine);

    int idxName = _findHeaderIndex(headers, ['teacher_name', 'name', 'teachername', 'fullname', 'full_name']);
    int idxEmp = _findHeaderIndex(headers, ['employee_id', 'employeeid', 'emp_id', 'empid', 'id']);
    int idxEmail = _findHeaderIndex(headers, ['email', 'teacher_email', 'mail']);
    int idxPhone = _findHeaderIndex(headers, ['phone', 'mobile', 'contact']);
    int idxSubjects = _findHeaderIndex(headers, ['assigned_subjects', 'subjects', 'subject']);
    int idxClasses = _findHeaderIndex(headers, ['assigned_classes', 'classes', 'class']);
    int idxYear = _findHeaderIndex(headers, ['academic_year', 'year']);

    final missingColumns = <String>[];
    if (idxName == -1) missingColumns.add('teacher_name');
    if (idxEmp == -1) missingColumns.add('employee_id');
    if (idxEmail == -1) missingColumns.add('email');

    if (missingColumns.isNotEmpty) {
      return CsvTeacherValidationResult(
        totalRows: lines.length - 1,
        validRows: [],
        invalidRows: [],
        globalErrors: [
          'Missing required columns: ${missingColumns.join(', ')}. Expected: teacher_name, employee_id, email, assigned_subjects, assigned_classes'
        ],
      );
    }

    final existingEmpIds = <String>{};
    try {
      final rosterQuery = await _firestore
          .collection('roster_teachers')
          .where('schoolId', isEqualTo: schoolId)
          .get();
      for (var doc in rosterQuery.docs) {
        final empId = doc.data()['employeeId']?.toString().trim();
        if (empId != null && empId.isNotEmpty) {
          existingEmpIds.add(empId);
        }
      }

      final usersQuery = await _firestore
          .collection('users')
          .where('schoolId', isEqualTo: schoolId)
          .where('role', isEqualTo: 'teacher')
          .get();
      for (var doc in usersQuery.docs) {
        final empId = doc.data()['employeeId']?.toString().trim();
        if (empId != null && empId.isNotEmpty) {
          existingEmpIds.add(empId);
        }
      }
    } catch (_) {}

    final seenEmpInFile = <String>{};
    final validRows = <CsvTeacherRow>[];
    final invalidRows = <CsvTeacherRow>[];

    for (int i = 1; i < lines.length; i++) {
      final rawLine = lines[i];
      final values = _parseCsvLine(rawLine);

      final name = idxName < values.length ? values[idxName].trim() : '';
      final empId = idxEmp < values.length ? values[idxEmp].trim() : '';
      final email = idxEmail < values.length ? values[idxEmail].trim() : '';
      final phone = idxPhone != -1 && idxPhone < values.length ? values[idxPhone].trim() : '';
      final subjectsRaw = idxSubjects != -1 && idxSubjects < values.length ? values[idxSubjects].trim() : 'General';
      final classesRaw = idxClasses != -1 && idxClasses < values.length ? values[idxClasses].trim() : 'All Classes';
      final year = idxYear != -1 && idxYear < values.length ? values[idxYear].trim() : '2026-2027';

      final subjectsList = subjectsRaw.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final classesList = classesRaw.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      String? rowError;
      if (name.isEmpty) {
        rowError = 'Missing teacher name';
      } else if (empId.isEmpty) {
        rowError = 'Missing employee ID';
      } else if (email.isEmpty || !email.contains('@')) {
        rowError = 'Invalid email address';
      } else if (seenEmpInFile.contains(empId)) {
        rowError = 'Duplicate employee ID in file ($empId)';
      } else if (existingEmpIds.contains(empId)) {
        rowError = 'Employee ID $empId already exists in this school';
      }

      final parsedRow = CsvTeacherRow(
        rowIndex: i + 1,
        teacherName: name,
        employeeId: empId,
        email: email,
        phone: phone,
        assignedSubjects: subjectsList.isNotEmpty ? subjectsList : ['General'],
        assignedClasses: classesList.isNotEmpty ? classesList : ['All Classes'],
        academicYear: year.isNotEmpty ? year : '2026-2027',
        verificationPin: generateVerificationPin(),
        isValid: rowError == null,
        error: rowError,
      );

      if (rowError == null) {
        seenEmpInFile.add(empId);
        validRows.add(parsedRow);
      } else {
        invalidRows.add(parsedRow);
      }
    }

    return CsvTeacherValidationResult(
      totalRows: lines.length - 1,
      validRows: validRows,
      invalidRows: invalidRows,
    );
  }

  /// Batch commit validated teacher roster records
  Future<CsvImportSummary> executeTeacherImport({
    required String schoolId,
    required String schoolCode,
    required List<CsvTeacherRow> rows,
  }) async {
    int teachersCreated = 0;
    final errors = <String>[];
    final batch = _firestore.batch();

    for (final row in rows) {
      if (!row.isValid) continue;

      try {
        final cleanCode = schoolCode.trim().toUpperCase();
        final rosterDocRef = _firestore
            .collection('roster_teachers')
            .doc('roster_tch_${cleanCode}_${row.employeeId}');

        final rosterModel = RosterTeacherModel(
          id: rosterDocRef.id,
          schoolId: schoolId,
          schoolCode: cleanCode,
          teacherName: row.teacherName,
          employeeId: row.employeeId,
          email: row.email,
          phone: row.phone.isNotEmpty ? row.phone : null,
          assignedSubjects: row.assignedSubjects,
          assignedClasses: row.assignedClasses,
          academicYear: row.academicYear,
          verificationPin: row.verificationPin,
          status: 'not_registered',
          createdAt: DateTime.now(),
        );

        batch.set(rosterDocRef, rosterModel.toMap());

        // Also add an unclaimed teacher record to users
        final userDocRef = _firestore.collection('users').doc('tch_pre_${cleanCode}_${row.employeeId}');
        final userModel = UserModel(
          id: userDocRef.id,
          name: row.teacherName,
          email: row.email,
          role: 'teacher',
          schoolId: schoolId,
          schoolCode: cleanCode,
          employeeId: row.employeeId,
          assignedSubjects: row.assignedSubjects,
          classIds: row.assignedClasses,
          academicYear: row.academicYear,
          isActive: false,
          status: 'not_registered',
        );

        batch.set(userDocRef, userModel.toMap(), SetOptions(merge: true));
        teachersCreated++;
      } catch (e) {
        errors.add('Failed on row ${row.rowIndex} (${row.teacherName}): $e');
      }
    }

    await batch.commit();

    final batchRecordRef = _firestore.collection('import_batches').doc();
    await batchRecordRef.set({
      'batchId': batchRecordRef.id,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'type': 'teachers',
      'totalProcessed': rows.length,
      'teachersCreated': teachersCreated,
      'errors': errors,
      'status': errors.isEmpty ? 'completed' : 'completed_with_errors',
      'importedAt': FieldValue.serverTimestamp(),
    });

    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'totalTeachers': FieldValue.increment(teachersCreated),
      });
    } catch (_) {}

    final auditService = AuditService();
    await auditService.logAction(
      action: 'TEACHERS_CSV_ROSTER_IMPORTED',
      targetType: 'school',
      targetId: schoolId,
      details: {
        'batchId': batchRecordRef.id,
        'schoolCode': schoolCode,
        'teachersCreated': teachersCreated,
        'errorCount': errors.length,
      },
    );

    return CsvImportSummary(
      totalProcessed: rows.length,
      teachersCreated: teachersCreated,
      errors: errors,
    );
  }

  // ── CSV Helpers ──────────────────────────────────────────────────────────
  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        values.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    values.add(sb.toString().trim());
    return values;
  }

  int _findHeaderIndex(List<String> headers, List<String> candidateNames) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].trim().replaceAll('"', '').replaceAll("'", '');
      for (final candidate in candidateNames) {
        if (h == candidate || h.contains(candidate)) {
          return i;
        }
      }
    }
    return -1;
  }
}
