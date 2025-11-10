class AppConstants {
  // Timer Constants
  static const int defaultStudyDuration = 25; // minutes
  static const int defaultBreakDuration = 5; // minutes
  static const int defaultLongBreakDuration = 15; // minutes
  static const int pomodoroSessions = 4; // sessions before long break

  // App Info
  static const String appName = 'Delta T';
  static const String appVersion = '1.0.0';

  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyStudyDuration = 'study_duration';
  static const String keyBreakDuration = 'break_duration';
  static const String keySoundEnabled = 'sound_enabled';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String notesCollection = 'notes';
  static const String sessionsCollection = 'sessions';
  static const String petsCollection = 'pets';

  // Tree Growth Stages
  static const List<String> treeStages = [
    '🌱', // Seed
    '🌿', // Sprout
    '🪴', // Young plant
    '🌳', // Small tree
    '🌲', // Medium tree
    '🎄', // Large tree
    '🌴', // Palm tree (full growth)
  ];
}
