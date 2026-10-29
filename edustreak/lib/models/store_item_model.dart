import 'package:cloud_firestore/cloud_firestore.dart';

class StoreItemModel {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji or icon name
  final int pointsCost;
  final String type; // avatar, badge, theme, etc.
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  StoreItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pointsCost,
    required this.type,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory StoreItemModel.fromMap(Map<String, dynamic> map) {
    return StoreItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      type: map['type'] ?? 'avatar',
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'pointsCost': pointsCost,
      'type': type,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static List<StoreItemModel> getDefaultItems() {
    return [
      StoreItemModel(
        id: 'avatar_1',
        name: 'Fire Avatar',
        description: 'A blazing fire avatar',
        icon: '🔥',
        pointsCost: 100,
        type: 'avatar',
        createdAt: DateTime.now(),
      ),
      StoreItemModel(
        id: 'avatar_2',
        name: 'Star Avatar',
        description: 'A shining star avatar',
        icon: '⭐',
        pointsCost: 150,
        type: 'avatar',
        createdAt: DateTime.now(),
      ),
      StoreItemModel(
        id: 'avatar_3',
        name: 'Crown Avatar',
        description: 'A royal crown avatar',
        icon: '👑',
        pointsCost: 200,
        type: 'avatar',
        createdAt: DateTime.now(),
      ),
      StoreItemModel(
        id: 'avatar_4',
        name: 'Rocket Avatar',
        description: 'A fast rocket avatar',
        icon: '🚀',
        pointsCost: 250,
        type: 'avatar',
        createdAt: DateTime.now(),
      ),
      StoreItemModel(
        id: 'avatar_5',
        name: 'Trophy Avatar',
        description: 'A golden trophy avatar',
        icon: '🏆',
        pointsCost: 300,
        type: 'avatar',
        createdAt: DateTime.now(),
      ),
      StoreItemModel(
        id: 'avatar_6',
        name: 'Diamond Avatar',
        description: 'A precious diamond avatar',
        icon: '💎',
        pointsCost: 500,
        type: 'avatar',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

