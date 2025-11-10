import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int currentStreak;
  final int totalStudyTime; // in minutes
  final int totalSessions;
  final DateTime createdAt;
  final DateTime lastActiveDate;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.currentStreak = 0,
    this.totalStudyTime = 0,
    this.totalSessions = 0,
    required this.createdAt,
    required this.lastActiveDate,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'currentStreak': currentStreak,
      'totalStudyTime': totalStudyTime,
      'totalSessions': totalSessions,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveDate': lastActiveDate.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      currentStreak: map['currentStreak'] ?? 0,
      totalStudyTime: map['totalStudyTime'] ?? 0,
      totalSessions: map['totalSessions'] ?? 0,
      createdAt: map['createdAt'] is String 
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as Timestamp).toDate(),
      lastActiveDate: map['lastActiveDate'] is String 
          ? DateTime.parse(map['lastActiveDate'])
          : (map['lastActiveDate'] as Timestamp).toDate(),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    int? currentStreak,
    int? totalStudyTime,
    int? totalSessions,
    DateTime? createdAt,
    DateTime? lastActiveDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currentStreak: currentStreak ?? this.currentStreak,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      totalSessions: totalSessions ?? this.totalSessions,
      createdAt: createdAt ?? this.createdAt,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}
