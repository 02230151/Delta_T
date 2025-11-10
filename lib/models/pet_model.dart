class PetModel {
  final String id;
  final String userId;
  final int consecutiveDays;
  final DateTime? lastStudyDate;
  final int totalSessions;

  PetModel({
    required this.id,
    required this.userId,
    this.consecutiveDays = 0,
    this.lastStudyDate,
    this.totalSessions = 0,
  });

  // Growth stage based on consecutive days (0-6)
  int get growthStage {
    if (consecutiveDays == 0) return 0; // Seed
    if (consecutiveDays <= 3) return 1; // Seedling
    if (consecutiveDays <= 5) return 2; // Small Sprout
    if (consecutiveDays <= 7) return 3; // Young Plant
    if (consecutiveDays <= 10) return 4; // Small Tree
    if (consecutiveDays <= 14) return 5; // Growing Tree
    return 6; // Full Tree
  }

  // Tree emoji based on growth stage with milestone enhancements
  String get treeEmoji {
    // Special milestone trees (after reaching full growth)
    if (consecutiveDays >= 365) return '🌴👑'; // 1 year - Royal Tree
    if (consecutiveDays >= 180) return '🌴💎'; // 6 months - Diamond Tree
    if (consecutiveDays >= 100) return '🌴⭐'; // 100 days - Star Tree
    if (consecutiveDays >= 50) return '🌴✨'; // 50 days - Sparkling Tree
    if (consecutiveDays >= 30) return '🌴🌟'; // 30 days - Shining Tree
    
    // Regular growth stages
    switch (growthStage) {
      case 0:
        return '🌰'; // Seed
      case 1:
        return '🌱'; // Seedling
      case 2:
        return '🌿'; // Small Sprout
      case 3:
        return '🪴'; // Young Plant
      case 4:
        return '🌳'; // Small Tree
      case 5:
        return '🌲'; // Growing Tree
      case 6:
        return '🌴'; // Full Tree
      default:
        return '🌰';
    }
  }

  // Stage name with milestone titles
  String get stageName {
    // Special milestone titles
    if (consecutiveDays >= 365) return 'Royal Tree';
    if (consecutiveDays >= 180) return 'Diamond Tree';
    if (consecutiveDays >= 100) return 'Century Tree';
    if (consecutiveDays >= 50) return 'Sparkling Tree';
    if (consecutiveDays >= 30) return 'Shining Tree';
    
    // Regular growth stages
    switch (growthStage) {
      case 0:
        return 'Seed';
      case 1:
        return 'Seedling';
      case 2:
        return 'Small Sprout';
      case 3:
        return 'Young Plant';
      case 4:
        return 'Small Tree';
      case 5:
        return 'Growing Tree';
      case 6:
        return 'Full Tree';
      default:
        return 'Seed';
    }
  }

  // Number of background trees (1 per week, max 8)
  int get backgroundTreeCount {
    final weeks = consecutiveDays ~/ 7;
    return weeks > 8 ? 8 : weeks;
  }

  // Get time difference in calendar days
  static int getTimeDifferenceInDays(DateTime now, DateTime lastDate) {
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final currentDay = DateTime(now.year, now.month, now.day);
    return currentDay.difference(lastDay).inDays;
  }
  
  // Check if streak should reset
  // Only resets if user hasn't studied today AND more than 1 day has passed
  bool shouldResetStreak() {
    if (lastStudyDate == null) return false;
    
    final now = DateTime.now();
    
    // If user studied today, don't reset
    if (hasStudiedToday()) {
      return false; // Keep streak - user studied today
    }
    
    // User hasn't studied today - check if more than 1 day has passed
    final daysDifference = getTimeDifferenceInDays(now, lastStudyDate!);
    
    // Reset only if more than 1 day has passed AND user hasn't studied today
    return daysDifference > 1;
  }

  // Check if already studied today (same calendar day)
  bool hasStudiedToday() {
    if (lastStudyDate == null) return false;
    
    final now = DateTime.now();
    return now.year == lastStudyDate!.year &&
        now.month == lastStudyDate!.month &&
        now.day == lastStudyDate!.day;
  }
  
  // Check if dates are consecutive (next day after last)
  bool isConsecutiveDay(DateTime now) {
    if (lastStudyDate == null) return false;
    
    final daysDifference = getTimeDifferenceInDays(now, lastStudyDate!);
    return daysDifference == 1; // Exactly 1 day difference = consecutive
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'consecutiveDays': consecutiveDays,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'totalSessions': totalSessions,
    };
  }

  // Create from Firestore document
  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      consecutiveDays: map['consecutiveDays'] ?? 0,
      lastStudyDate: map['lastStudyDate'] != null
          ? DateTime.parse(map['lastStudyDate'])
          : null,
      totalSessions: map['totalSessions'] ?? 0,
    );
  }

  // Copy with method for updates
  PetModel copyWith({
    String? id,
    String? userId,
    int? consecutiveDays,
    DateTime? lastStudyDate,
    int? totalSessions,
  }) {
    return PetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}
