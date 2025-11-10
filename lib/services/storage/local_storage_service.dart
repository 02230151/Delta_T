import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for persisting user data and app state
/// Mimics localStorage behavior with keys:
/// - 'delta-t-auth' for authentication
/// - 'delta-t-settings' for timer settings
/// - 'delta-t-sessions' for session history
class LocalStorageService {
  static const String _authKey = 'delta-t-auth';
  static const String _userIdKey = 'delta-t-user-id';
  static const String _userEmailKey = 'delta-t-user-email';
  static const String _userNameKey = 'delta-t-user-name';
  static const String _isLoggedInKey = 'delta-t-is-logged-in';
  
  // Settings key (stores all settings as JSON)
  static const String _settingsKey = 'delta-t-settings';
  static const String _studyHistoryKey = 'delta-t-study-history';
  
  // Sessions key (stores session history as JSON array)
  static const String _sessionsKey = 'delta-t-sessions';
  
  // Tasks key (stores tasks as JSON array)
  static const String _tasksKey = 'delta-t-tasks';
  
  // Notes key (stores notes as JSON array)
  static const String _notesKey = 'delta-t-notes';
  
  // Progress key (stores progress data as JSON)
  static const String _progressKey = 'delta-t-progress';
  
  // Achievements key (stores achievements as JSON array)
  static const String _achievementsKey = 'delta-t-achievements';
  
  // Individual setting keys (for backward compatibility)
  static const String _studyDurationKey = 'delta-t-study-duration';
  static const String _breakDurationKey = 'delta-t-break-duration';
  static const String _longBreakDurationKey = 'delta-t-long-break-duration';
  static const String _soundEnabledKey = 'delta-t-sound-enabled';
  
  // Theme
  static const String _themeKey = 'delta-t-theme';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save authentication state
  static Future<bool> saveAuthState({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    await init();
    final results = await Future.wait([
      _prefs!.setString(_userIdKey, userId),
      _prefs!.setString(_userEmailKey, email),
      _prefs!.setString(_userNameKey, displayName),
      _prefs!.setBool(_isLoggedInKey, true),
      _prefs!.setString(_authKey, userId), // Main auth key
    ]);
    return results.every((result) => result);
  }

  /// Clear authentication state (logout)
  static Future<bool> clearAuthState() async {
    await init();
    final results = await Future.wait([
      _prefs!.remove(_userIdKey),
      _prefs!.remove(_userEmailKey),
      _prefs!.remove(_userNameKey),
      _prefs!.setBool(_isLoggedInKey, false),
      _prefs!.remove(_authKey),
    ]);
    return results.every((result) => result);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    await init();
    return _prefs!.getBool(_isLoggedInKey) ?? false;
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    await init();
    return _prefs!.getString(_userIdKey);
  }

  /// Get stored user email
  static Future<String?> getUserEmail() async {
    await init();
    return _prefs!.getString(_userEmailKey);
  }

  /// Get stored user name
  static Future<String?> getUserName() async {
    await init();
    return _prefs!.getString(_userNameKey);
  }

  /// Save settings per user (stored as JSON object with userId as key)
  static Future<bool> saveSettings({
    required String userId,
    required int studyDuration,
    required int breakDuration,
    required int longBreakDuration,
    required bool soundEnabled,
  }) async {
    await init();
    
    // Clamp values between 1-120 minutes
    final clampedStudy = studyDuration.clamp(1, 120);
    final clampedBreak = breakDuration.clamp(1, 120);
    final clampedLongBreak = longBreakDuration.clamp(1, 120);
    
    // Get all settings
    final allSettings = await _getAllSettings();
    
    // Update this user's settings
    allSettings[userId] = {
      'studyDuration': clampedStudy,
      'breakDuration': clampedBreak,
      'longBreakDuration': clampedLongBreak,
      'soundEnabled': soundEnabled,
    };
    
    final jsonString = jsonEncode(allSettings);
    return await _prefs!.setString(_settingsKey, jsonString);
  }

  /// Get settings for specific user from 'delta-t-settings'
  static Future<Map<String, dynamic>> getSettings({String? userId}) async {
    await init();
    
    // If no userId provided, try to get current user
    final targetUserId = userId ?? await getUserId();
    if (targetUserId == null) {
      return _getDefaultSettings();
    }
    
    final allSettings = await _getAllSettings();
    
    // Return user's settings or defaults
    if (allSettings.containsKey(targetUserId)) {
      return allSettings[targetUserId] as Map<String, dynamic>;
    }
    
    return _getDefaultSettings();
  }

  /// Get all settings (internal helper)
  static Future<Map<String, dynamic>> _getAllSettings() async {
    await init();
    final jsonString = _prefs!.getString(_settingsKey);
    
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    
    return {};
  }

  /// Default settings
  static Map<String, dynamic> _getDefaultSettings() {
    return {
      'studyDuration': 25,
      'breakDuration': 5,
      'longBreakDuration': 15,
      'soundEnabled': true,
    };
  }

  /// Save sound enabled state
  static Future<bool> setSoundEnabled(bool enabled) async {
    await init();
    return await _prefs!.setBool(_soundEnabledKey, enabled);
  }

  /// Get sound enabled state
  static Future<bool> isSoundEnabled() async {
    await init();
    return _prefs!.getBool(_soundEnabledKey) ?? true;
  }

  /// Save theme mode
  static Future<bool> setThemeMode(String theme) async {
    await init();
    return await _prefs!.setString(_themeKey, theme);
  }

  /// Get theme mode
  static Future<String> getThemeMode() async {
    await init();
    return _prefs!.getString(_themeKey) ?? 'light';
  }

  /// Save session to 'delta-t-sessions' array
  static Future<bool> saveSession({
    required String sessionId,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    required String sessionType, // 'pomodoro' or 'standard'
  }) async {
    await init();
    
    final sessions = await getSessions();
    
    final newSession = {
      'id': sessionId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'sessionType': sessionType,
      'date': DateTime(startTime.year, startTime.month, startTime.day).toIso8601String(),
    };
    
    sessions.add(newSession);
    
    final jsonString = jsonEncode(sessions);
    return await _prefs!.setString(_sessionsKey, jsonString);
  }

  /// Get all sessions from 'delta-t-sessions'
  static Future<List<Map<String, dynamic>>> getSessions() async {
    await init();
    final jsonString = _prefs!.getString(_sessionsKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    
    return [];
  }

  /// Get today's sessions for a specific user
  static Future<List<Map<String, dynamic>>> getTodaySessions({String? userId}) async {
    final sessions = await getSessions();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day).toIso8601String();
    
    return sessions.where((session) {
      final matchesDate = session['date'] == todayDate;
      final matchesUser = userId == null || session['userId'] == userId;
      return matchesDate && matchesUser;
    }).toList();
  }

  /// Get session count for today for a specific user
  static Future<int> getTodaySessionCount({String? userId}) async {
    final todaySessions = await getTodaySessions(userId: userId);
    return todaySessions.length;
  }

  /// Get total study minutes for today for a specific user
  static Future<int> getTodayStudyMinutes({String? userId}) async {
    final todaySessions = await getTodaySessions(userId: userId);
    int totalMinutes = 0;
    
    for (var session in todaySessions) {
      totalMinutes += (session['durationMinutes'] as int? ?? 0);
    }
    
    return totalMinutes;
  }

  /// Clear old sessions (keep last 90 days)
  static Future<bool> clearOldSessions() async {
    await init();
    final sessions = await getSessions();
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    
    final recentSessions = sessions.where((session) {
      try {
        final sessionDate = DateTime.parse(session['date'] as String);
        return sessionDate.isAfter(cutoffDate);
      } catch (e) {
        return false;
      }
    }).toList();
    
    final jsonString = jsonEncode(recentSessions);
    return await _prefs!.setString(_sessionsKey, jsonString);
  }

  /// Save task to 'delta-t-tasks' array
  static Future<bool> saveTask({
    required String taskId,
    required String userId,
    required String title,
    String? description,
    required bool isCompleted,
    required DateTime createdAt,
    DateTime? completedAt,
  }) async {
    await init();
    
    final tasks = await getTasks();
    
    // Check if task already exists (update)
    final existingIndex = tasks.indexWhere((task) => task['id'] == taskId);
    
    final taskData = {
      'id': taskId,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
    
    if (existingIndex >= 0) {
      // Update existing task
      tasks[existingIndex] = taskData;
    } else {
      // Add new task
      tasks.add(taskData);
    }
    
    final jsonString = jsonEncode(tasks);
    return await _prefs!.setString(_tasksKey, jsonString);
  }

  /// Get all tasks from 'delta-t-tasks'
  static Future<List<Map<String, dynamic>>> getTasks() async {
    await init();
    final jsonString = _prefs!.getString(_tasksKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    
    return [];
  }

  /// Get tasks for specific user
  static Future<List<Map<String, dynamic>>> getUserTasks(String userId) async {
    final tasks = await getTasks();
    return tasks.where((task) => task['userId'] == userId).toList();
  }

  /// Delete task from 'delta-t-tasks'
  static Future<bool> deleteTask(String taskId) async {
    await init();
    final tasks = await getTasks();
    
    tasks.removeWhere((task) => task['id'] == taskId);
    
    final jsonString = jsonEncode(tasks);
    return await _prefs!.setString(_tasksKey, jsonString);
  }

  /// Get task statistics
  static Future<Map<String, int>> getTaskStatistics(String userId) async {
    final tasks = await getUserTasks(userId);
    
    final total = tasks.length;
    final completed = tasks.where((task) => task['isCompleted'] == true).length;
    final pending = total - completed;
    
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
    };
  }

  /// Check if user has completed 10+ tasks (Task Master achievement)
  static Future<bool> hasTaskMasterAchievement(String userId) async {
    final stats = await getTaskStatistics(userId);
    return (stats['completed'] ?? 0) >= 10;
  }

  // ========== NOTES OPERATIONS ==========

  /// Save note to 'delta-t-notes'
  static Future<bool> saveNote({
    required String noteId,
    required String userId,
    required String title,
    required String content,
    required DateTime createdAt,
  }) async {
    await init();
    
    final notes = await getNotes();
    
    // Check if note already exists (update)
    final existingIndex = notes.indexWhere((n) => n['id'] == noteId);
    
    final note = {
      'id': noteId,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    if (existingIndex >= 0) {
      notes[existingIndex] = note;
    } else {
      notes.insert(0, note); // Add to beginning (newest first)
    }
    
    final jsonString = jsonEncode(notes);
    return await _prefs!.setString(_notesKey, jsonString);
  }

  /// Get all notes from 'delta-t-notes'
  static Future<List<Map<String, dynamic>>> getNotes() async {
    await init();
    final jsonString = _prefs!.getString(_notesKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    
    return [];
  }

  /// Get notes for specific user
  static Future<List<Map<String, dynamic>>> getUserNotes(String userId) async {
    final notes = await getNotes();
    return notes.where((note) => note['userId'] == userId).toList();
  }

  /// Delete note from 'delta-t-notes'
  static Future<bool> deleteNote(String noteId) async {
    await init();
    
    final notes = await getNotes();
    notes.removeWhere((note) => note['id'] == noteId);
    
    final jsonString = jsonEncode(notes);
    return await _prefs!.setString(_notesKey, jsonString);
  }

  /// Get note count for user
  static Future<int> getNoteCount(String userId) async {
    final notes = await getUserNotes(userId);
    return notes.length;
  }

  // ========== PROGRESS OPERATIONS ==========

  /// Save progress data to 'delta-t-progress' (per user)
  static Future<bool> saveProgress({
    required String userId,
    required int currentStreak,
    required DateTime? lastStudyDate,
    required int totalSessions,
    required int totalMinutes,
  }) async {
    await init();
    
    // Get all progress data
    final allProgress = await _getAllProgress();
    
    // Update this user's progress
    allProgress[userId] = {
      'userId': userId,
      'currentStreak': currentStreak,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    final jsonString = jsonEncode(allProgress);
    return await _prefs!.setString(_progressKey, jsonString);
  }

  /// Get progress data from 'delta-t-progress' for specific user
  static Future<Map<String, dynamic>> getProgress({String? userId}) async {
    await init();
    
    if (userId == null) {
      userId = await getUserId();
    }
    
    if (userId == null) {
      return _getDefaultProgress();
    }
    
    final allProgress = await _getAllProgress();
    
    if (allProgress.containsKey(userId)) {
      return allProgress[userId] as Map<String, dynamic>;
    }
    
    return _getDefaultProgress();
  }

  /// Get all progress data (internal helper)
  static Future<Map<String, dynamic>> _getAllProgress() async {
    await init();
    final jsonString = _prefs!.getString(_progressKey);
    
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    
    return {};
  }

  /// Default progress data
  static Map<String, dynamic> _getDefaultProgress() {
    return {
      'userId': '',
      'currentStreak': 0,
      'lastStudyDate': null,
      'totalSessions': 0,
      'totalMinutes': 0,
    };
  }

  // ========== ACHIEVEMENTS OPERATIONS ==========

  /// Save achievement to 'delta-t-achievements'
  static Future<bool> unlockAchievement({
    required String achievementId,
    required String userId,
    required String title,
    required String description,
    required String icon,
  }) async {
    await init();
    
    final achievements = await getAchievements();
    
    // Check if already unlocked
    final exists = achievements.any((a) => a['id'] == achievementId);
    if (exists) return true;
    
    final achievement = {
      'id': achievementId,
      'userId': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedAt': DateTime.now().toIso8601String(),
    };
    
    achievements.add(achievement);
    
    final jsonString = jsonEncode(achievements);
    return await _prefs!.setString(_achievementsKey, jsonString);
  }

  /// Get all achievements from 'delta-t-achievements'
  static Future<List<Map<String, dynamic>>> getAchievements() async {
    await init();
    final jsonString = _prefs!.getString(_achievementsKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    
    return [];
  }

  /// Check if achievement is unlocked
  static Future<bool> isAchievementUnlocked(String achievementId) async {
    final achievements = await getAchievements();
    return achievements.any((a) => a['id'] == achievementId);
  }

  /// Get unlocked achievements for user
  static Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    final achievements = await getAchievements();
    return achievements.where((a) => a['userId'] == userId).toList();
  }

  /// Get weekly study data (last 7 days)
  static Future<List<Map<String, dynamic>>> getWeeklyStudyData() async {
    final sessions = await getSessions();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    // Group sessions by date
    final Map<String, int> dailyMinutes = {};
    
    for (var session in sessions) {
      try {
        final sessionDate = DateTime.parse(session['date'] as String);
        if (sessionDate.isAfter(weekAgo)) {
          final dateKey = session['date'] as String;
          dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + 
                                  (session['durationMinutes'] as int? ?? 0);
        }
      } catch (e) {
        continue;
      }
    }
    
    // Create 7-day array
    final List<Map<String, dynamic>> weekData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day).toIso8601String();
      
      weekData.add({
        'date': dateKey,
        'dayName': _getDayName(date.weekday),
        'minutes': dailyMinutes[dateKey] ?? 0,
        'hasStudied': (dailyMinutes[dateKey] ?? 0) > 0,
      });
    }
    
    return weekData;
  }

  /// Get day name from weekday number
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  // ========== CALENDAR STUDY HISTORY ==========

  /// Save study minutes for a specific date
  static Future<bool> saveStudyHistoryForDate({
    required String userId,
    required DateTime date,
    required int minutes,
  }) async {
    await init();
    
    // Normalize date to start of day
    final dateKey = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    
    // Get existing history
    final history = await _getStudyHistory();
    
    // Create user history if doesn't exist
    if (!history.containsKey(userId)) {
      history[userId] = {};
    }
    
    // Update minutes for this date
    history[userId][dateKey] = minutes;
    
    // Save back to storage
    final jsonString = jsonEncode(history);
    return await _prefs!.setString(_studyHistoryKey, jsonString);
  }

  /// Get study minutes for a specific date
  static Future<int> getStudyMinutesForDate({
    required String userId,
    required DateTime date,
  }) async {
    await init();
    
    final dateKey = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    final history = await _getStudyHistory();
    
    if (history.containsKey(userId) && history[userId].containsKey(dateKey)) {
      return history[userId][dateKey] as int;
    }
    
    return 0;
  }

  /// Get study history for entire month
  static Future<Map<String, int>> getMonthStudyHistory({
    required String userId,
    required int year,
    required int month,
  }) async {
    await init();
    
    final history = await _getStudyHistory();
    final monthData = <String, int>{};
    
    if (!history.containsKey(userId)) {
      return monthData;
    }
    
    final userHistory = history[userId] as Map<String, dynamic>;
    
    // Filter dates for this month
    for (var entry in userHistory.entries) {
      final dateKey = entry.key;
      final dateParts = dateKey.split('-');
      
      if (dateParts.length == 3) {
        final entryYear = int.parse(dateParts[0]);
        final entryMonth = int.parse(dateParts[1]);
        
        if (entryYear == year && entryMonth == month) {
          monthData[dateKey] = entry.value as int;
        }
      }
    }
    
    return monthData;
  }

  /// Get all study history for user (for calendar view)
  static Future<Map<String, int>> getAllStudyHistory(String userId) async {
    await init();
    
    final history = await _getStudyHistory();
    
    if (!history.containsKey(userId)) {
      return {};
    }
    
    final userHistory = history[userId] as Map<String, dynamic>;
    return userHistory.map((key, value) => MapEntry(key, value as int));
  }

  /// Internal helper to get study history
  static Future<Map<String, dynamic>> _getStudyHistory() async {
    await init();
    final jsonString = _prefs!.getString(_studyHistoryKey);
    
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    
    return {};
  }

  /// Clear all app data
  static Future<bool> clearAll() async {
    await init();
    return await _prefs!.clear();
  }
}
