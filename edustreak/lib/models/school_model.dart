import 'package:flutter/material.dart';

enum SchoolType {
  government,
  privateSchool,
  cbse,
}

extension SchoolTypeExtension on SchoolType {
  String get displayName {
    switch (this) {
      case SchoolType.government:
        return 'AP Government';
      case SchoolType.privateSchool:
        return 'Private';
      case SchoolType.cbse:
        return 'CBSE';
    }
  }

  Color get color {
    switch (this) {
      case SchoolType.government:
        return const Color(0xFF7C6FFF); // Violet
      case SchoolType.privateSchool:
        return const Color(0xFF00E5FF); // Cyan
      case SchoolType.cbse:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String get defaultCurriculumCode {
    switch (this) {
      case SchoolType.government:
        return 'AP_STATE_GOVT';
      case SchoolType.privateSchool:
        return 'PRIVATE_CUSTOM';
      case SchoolType.cbse:
        return 'CBSE_CENTRAL';
    }
  }
}

class SchoolModel {
  final String id;
  final String name;
  final String code;
  final SchoolType type;
  final String status; // 'active', 'suspended', 'archived'
  final String address;
  final String mandal;
  final String district;
  final String state;
  final String pincode;
  final String cityOrVillage;
  final String contactPerson;
  final String contactPhone;
  final String contactEmail;
  final String? principalId;
  final String? principalName;
  final String? principalEmail;
  final String affiliationNumber;
  final String academicYear;
  final List<String> supportedClasses;
  final String? logoUrl;
  final int totalStudents;
  final int totalTeachers;
  final String curriculumTemplateId;
  final DateTime establishedDate;
  final DateTime? updatedAt;

  const SchoolModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.status = 'active',
    this.address = '',
    this.mandal = '',
    this.cityOrVillage = '',
    required this.district,
    this.state = 'Andhra Pradesh',
    this.pincode = '',
    this.contactPerson = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.principalId,
    this.principalName,
    this.principalEmail,
    this.affiliationNumber = '',
    this.academicYear = '2024-2025',
    this.supportedClasses = const [
      'Class 6',
      'Class 7',
      'Class 8',
      'Class 9',
      'Class 10',
    ],
    this.logoUrl,
    required this.totalStudents,
    required this.totalTeachers,
    required this.curriculumTemplateId,
    required this.establishedDate,
    this.updatedAt,
    bool? isActive,
  });

  bool get isActive => status == 'active';
  bool get isPendingApproval => status == 'pending_approval';
  bool get isSuspended => status == 'suspended';
  bool get isDeactivated => status == 'deactivated';
  bool get hasPrincipalAssigned => principalId != null && principalId!.isNotEmpty;

  SchoolModel copyWith({
    String? id,
    String? name,
    String? code,
    SchoolType? type,
    String? status,
    String? address,
    String? mandal,
    String? cityOrVillage,
    String? district,
    String? state,
    String? pincode,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    String? principalId,
    String? principalName,
    String? principalEmail,
    String? affiliationNumber,
    String? academicYear,
    List<String>? supportedClasses,
    String? logoUrl,
    int? totalStudents,
    int? totalTeachers,
    String? curriculumTemplateId,
    DateTime? establishedDate,
    DateTime? updatedAt,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      status: status ?? this.status,
      address: address ?? this.address,
      mandal: mandal ?? this.mandal,
      cityOrVillage: cityOrVillage ?? this.cityOrVillage,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      principalId: principalId ?? this.principalId,
      principalName: principalName ?? this.principalName,
      principalEmail: principalEmail ?? this.principalEmail,
      affiliationNumber: affiliationNumber ?? this.affiliationNumber,
      academicYear: academicYear ?? this.academicYear,
      supportedClasses: supportedClasses ?? this.supportedClasses,
      logoUrl: logoUrl ?? this.logoUrl,
      totalStudents: totalStudents ?? this.totalStudents,
      totalTeachers: totalTeachers ?? this.totalTeachers,
      curriculumTemplateId: curriculumTemplateId ?? this.curriculumTemplateId,
      establishedDate: establishedDate ?? this.establishedDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type.name,
      'status': status,
      'isActive': isActive,
      'address': address,
      'mandal': mandal,
      'cityOrVillage': cityOrVillage,
      'district': district,
      'state': state,
      'pincode': pincode,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'principalId': principalId,
      'principalName': principalName,
      'principalEmail': principalEmail,
      'affiliationNumber': affiliationNumber,
      'academicYear': academicYear,
      'supportedClasses': supportedClasses,
      'logoUrl': logoUrl,
      'totalStudents': totalStudents,
      'totalTeachers': totalTeachers,
      'curriculumTemplateId': curriculumTemplateId,
      'establishedDate': establishedDate.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory SchoolModel.fromMap(Map<String, dynamic> map, String docId) {
    // Resolve status gracefully
    String resolvedStatus = 'active';
    if (map.containsKey('status')) {
      resolvedStatus = map['status'] ?? 'active';
    } else if (map.containsKey('isActive')) {
      resolvedStatus = map['isActive'] == false ? 'suspended' : 'active';
    }

    return SchoolModel(
      id: docId,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      type: SchoolType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SchoolType.government,
      ),
      status: resolvedStatus,
      address: map['address'] ?? '',
      mandal: map['mandal'] ?? '',
      cityOrVillage: map['cityOrVillage'] ?? map['city'] ?? map['village'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? 'Andhra Pradesh',
      pincode: map['pincode'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      principalId: map['principalId'],
      principalName: map['principalName'],
      principalEmail: map['principalEmail'],
      affiliationNumber: map['affiliationNumber'] ?? '',
      academicYear: map['academicYear'] ?? '2024-2025',
      supportedClasses: map['supportedClasses'] != null
          ? List<String>.from(map['supportedClasses'])
          : const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'],
      logoUrl: map['logoUrl'],
      totalStudents: (map['totalStudents'] as num?)?.toInt() ?? 0,
      totalTeachers: (map['totalTeachers'] as num?)?.toInt() ?? 0,
      curriculumTemplateId: map['curriculumTemplateId'] ?? 'AP_STATE_GOVT',
      establishedDate: map['establishedDate'] != null
          ? DateTime.tryParse(map['establishedDate']) ?? DateTime(2020)
          : DateTime(2020),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
    );
  }
}
