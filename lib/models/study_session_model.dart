class StudySessionModel {
  final String id;
  final String userId;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final String sessionType; // 'pomodoro' or 'standard'

  StudySessionModel({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.sessionType,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'sessionType': sessionType,
    };
  }

  // Create from Firestore document
  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      sessionType: map['sessionType'] ?? 'standard',
    );
  }
}
