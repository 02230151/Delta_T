import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/storage/local_storage_service.dart';
import '../services/notification_service.dart';

enum TimerState { idle, running, paused }
enum TimerMode { pomodoro, standard }

class TimerProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  TimerState _timerState = TimerState.idle;
  TimerMode _timerMode = TimerMode.pomodoro;
  
  int _studyTime = 25; // in minutes
  int _breakTime = 5; // in minutes
  int _remainingTime = 25 * 60; // in seconds (for pomodoro) or elapsed time (for standard)
  bool _soundNotifications = true;
  
  bool _isBreakTime = false;
  int _currentSession = 1;
  int _completedSessionsToday = 0;
  
  Timer? _timer;
  DateTime? _sessionStartTime;
  String? _userId;
  
  // Day tracking for automatic reset
  DateTime? _lastCheckedDate;
  Timer? _dayCheckTimer;
  
  // Callbacks for session events
  Function()? onSessionComplete; // Called when study session completes
  Function(String message)? onShowToast; // Called to show toast messages
  
  // Statistics
  int _totalStudyMinutesToday = 0;

  // Getters
  TimerState get timerState => _timerState;
  TimerMode get timerMode => _timerMode;
  int get remainingTime => _remainingTime;
  int get studyTime => _studyTime;
  int get breakTime => _breakTime;
  bool get soundNotifications => _soundNotifications;
  bool get isBreakTime => _isBreakTime;
  bool get isRunning => _timerState == TimerState.running;
  int get currentSession => _currentSession;
  int get completedSessionsToday => _completedSessionsToday;
  int get totalStudyMinutesToday => _totalStudyMinutesToday;
  double get progress {
    final totalTime = _isBreakTime ? _breakTime * 60 : _studyTime * 60;
    return totalTime > 0 ? _remainingTime / totalTime : 0;
  }
  
  // Progress percentage (0-100)
  double get progressPercentage => (1 - progress) * 100;

  // Initialize with user ID and load settings
  void initialize(String userId) async {
    _userId = userId;
    _lastCheckedDate = DateTime.now();
    await _loadProgressFromFirestore();
    await _loadSettings();
    await _loadTodayStatistics();
    _startDayCheckTimer();
  }
  
  // Start timer to check for day changes
  void _startDayCheckTimer() {
    _dayCheckTimer?.cancel();
    // Check every minute if day has changed
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkDayChange();
    });
  }
  
  // Check if day has changed and reset if needed
  Future<void> _checkDayChange() async {
    if (_userId == null || _lastCheckedDate == null) return;
    
    final now = DateTime.now();
    final lastDate = DateTime(
      _lastCheckedDate!.year,
      _lastCheckedDate!.month,
      _lastCheckedDate!.day,
    );
    final currentDate = DateTime(now.year, now.month, now.day);
    
    // If day has changed, reset today's statistics
    if (currentDate.isAfter(lastDate)) {
      debugPrint('Day changed detected - resetting today\'s statistics');
      
      // Save yesterday's final progress to calendar history (both localStorage and Firestore)
      if (_completedSessionsToday > 0 || _totalStudyMinutesToday > 0) {
        await LocalStorageService.saveStudyHistoryForDate(
          userId: _userId!,
          date: _lastCheckedDate!,
          minutes: _totalStudyMinutesToday,
        );
        
        // Save to Firestore calendar history (persists across logins)
        await _firestoreService.saveCalendarHistory(
          userId: _userId!,
          date: _lastCheckedDate!,
          minutes: _totalStudyMinutesToday,
        );
      }
      
      // Reset today's counters
      _completedSessionsToday = 0;
      _totalStudyMinutesToday = 0;
      _currentSession = 1;
      _lastCheckedDate = now;
      
      // Reload today's statistics from Firestore (should be 0 for new day)
      await _loadTodayStatistics();
      
      // Notify listeners to update UI
      notifyListeners();
    }
  }

  // Load progress from Firestore and sync to LocalStorage
  Future<void> _loadProgressFromFirestore() async {
    if (_userId == null) return;

    try {
      // Get progress from Firestore
      final firestoreProgress = await _firestoreService.getUserProgress(_userId!);
      
      if (firestoreProgress != null) {
        // Sync to LocalStorage
        final totalSessions = firestoreProgress['totalSessions'] as int? ?? 0;
        final totalMinutes = firestoreProgress['totalMinutes'] as int? ?? 0;
        final lastStudyTimestamp = firestoreProgress['lastStudyDate'];
        
        DateTime? lastStudyDate;
        if (lastStudyTimestamp != null) {
          lastStudyDate = (lastStudyTimestamp as Timestamp).toDate();
        }
        
        // Save to LocalStorage
        await LocalStorageService.saveProgress(
          userId: _userId!,
          currentStreak: 0, // Will be calculated based on dates
          totalSessions: totalSessions,
          totalMinutes: totalMinutes,
          lastStudyDate: lastStudyDate,
        );
      }
    } catch (e) {
      // If Firestore fails, continue with LocalStorage data
      debugPrint('Error loading progress from Firestore: $e');
    }
  }

  // Load settings from localStorage (delta-t-settings) for this user
  Future<void> _loadSettings() async {
    if (_userId == null) return;
    
    final settings = await LocalStorageService.getSettings(userId: _userId);
    _studyTime = settings['studyDuration'] ?? 25;
    _breakTime = settings['breakDuration'] ?? 5;
    _soundNotifications = settings['soundEnabled'] ?? true;
    _resetTimer();
    notifyListeners();
  }

  // Start timer
  void startTimer() {
    if (_timerState == TimerState.idle) {
      _sessionStartTime = DateTime.now();
    }
    
    _timerState = TimerState.running;
    _startTimer();
    notifyListeners();
  }

  // Pause timer
  void pauseTimer() {
    _timer?.cancel();
    _timerState = TimerState.paused;
    notifyListeners();
  }

  // Resume timer
  void resumeTimer() {
    _timerState = TimerState.running;
    _startTimer();
    notifyListeners();
  }

  // Stop timer (for standard mode - local only, no saving)
  Future<void> stopTimer() async {
    _timer?.cancel();
    
    // Standard mode: Just stop the timer, don't save anything
    // This is a local-only timer for user convenience
    
    _timerState = TimerState.idle;
    _resetTimer();
    notifyListeners();
  }

  // Reset timer
  void resetTimer() {
    _timer?.cancel();
    _timerState = TimerState.idle;
    _isBreakTime = false;
    _currentSession = 1;
    _resetTimer();
    notifyListeners();
  }

  // Set timer mode
  void setTimerMode(TimerMode mode) {
    if (_timerMode == mode) return; // Already in this mode
    
    // Stop timer if running
    if (_timerState != TimerState.idle) {
      _timer?.cancel();
      _timerState = TimerState.idle;
    }
    
    _timerMode = mode;
    _resetTimer();
    notifyListeners();
  }

  // Update settings and save to localStorage for this user
  Future<bool> updateSettings({
    required int studyTime,
    required int breakTime,
    required bool soundNotifications,
  }) async {
    if (_userId == null) return false;
    
    // Clamp values between 1-120 minutes
    _studyTime = studyTime.clamp(1, 120);
    _breakTime = breakTime.clamp(1, 60);
    _soundNotifications = soundNotifications;
    
    // Save to localStorage with userId
    final success = await LocalStorageService.saveSettings(
      userId: _userId!,
      studyDuration: _studyTime,
      breakDuration: _breakTime,
      longBreakDuration: 15, // Keep for backward compatibility
      soundEnabled: _soundNotifications,
    );
    
    // Reset timer with new settings if idle
    if (_timerState == TimerState.idle) {
      _resetTimer();
    }
    notifyListeners();
    
    return success;
  }

  // Private helper methods
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerMode == TimerMode.standard) {
        // Standard mode: COUNT UP
        _remainingTime++;
        // Notify every second for smooth count-up display
        notifyListeners();
      } else {
        // Pomodoro mode: COUNT DOWN
        if (_remainingTime > 0) {
          _remainingTime--;
          // Notify every second for pomodoro (important for countdown)
          notifyListeners();
        } else {
          _onTimerComplete();
        }
      }
    });
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();

    if (_timerMode == TimerMode.pomodoro) {
      if (!_isBreakTime) {
        // Study session completed - update stats first
        _completedSessionsToday++;
        _totalStudyMinutesToday += _studyTime;
        _currentSession++;
        
        // Switch to break and AUTO-START immediately (before any async operations)
        _isBreakTime = true;
        _remainingTime = _breakTime * 60;
        _timerState = TimerState.running;
        
        // Notify UI immediately so break timer starts showing right away
        notifyListeners();
        
        // Start break timer automatically right away (don't wait for anything)
        _startTimer();
        
        // Do all async operations in background (don't block UI or timer)
        // Save session first, then update progress
        _saveSession().then((_) async {
          // After session is saved, update progress
          await _saveProgressToDatabase();
          // Notify pet provider about completed session
          debugPrint('🎯 Calling onSessionComplete callback...');
          onSessionComplete?.call();
          debugPrint('✅ onSessionComplete callback called');
        }).catchError((e) {
          debugPrint('Error saving session: $e');
        });
        
        // Show system notification (async, won't block)
        final notificationService = NotificationService();
        // Ensure notification service is initialized
        await notificationService.initialize();
        await notificationService.showNotification(
          id: 1,
          title: '🎉 Study Session Complete!',
          body: 'Great work! Break time started.',
        );
        
        // Show break start notification after a short delay
        Future.delayed(const Duration(seconds: 1), () async {
          await notificationService.showNotification(
            id: 2,
            title: '☕ Break Time Started',
            body: 'Relax for ${_breakTime} minutes.',
          );
        });
      } else {
        // Break completed
        _isBreakTime = false;
        _remainingTime = _studyTime * 60;
        _timerState = TimerState.idle;
        
        // Notify UI immediately
        notifyListeners();
        
        // Show system notification (async, won't block)
        final notificationService = NotificationService();
        // Ensure notification service is initialized
        await notificationService.initialize();
        await notificationService.showNotification(
          id: 3,
          title: '💪 Break Over!',
          body: 'Ready for next study session?',
        );
      }
    } else {
      // Standard mode - user manually stops
      // This won't be called automatically in standard mode
      notifyListeners();
    }
  }

  void _resetTimer() {
    if (_timerMode == TimerMode.standard) {
      _remainingTime = 0; // Standard mode starts at 0
    } else {
      _remainingTime = _isBreakTime ? _breakTime * 60 : _studyTime * 60;
    }
  }

  Future<void> _saveSession() async {
    if (_userId != null && _sessionStartTime != null) {
      final sessionId = const Uuid().v4();
      final endTime = DateTime.now();
      final sessionType = _timerMode == TimerMode.pomodoro ? 'pomodoro' : 'standard';
      
      final session = StudySessionModel(
        id: sessionId,
        userId: _userId!,
        durationMinutes: _studyTime,
        startTime: _sessionStartTime!,
        endTime: endTime,
        sessionType: sessionType,
      );

      // Save to Firestore first (source of truth)
      await _firestoreService.createStudySession(session);
      
      // Save to localStorage (delta-t-sessions) for offline access
      await LocalStorageService.saveSession(
        sessionId: sessionId,
        userId: _userId!,
        startTime: _sessionStartTime!,
        endTime: endTime,
        durationMinutes: _studyTime,
        sessionType: sessionType,
      );
    }
  }

  Future<void> _loadTodayStatistics() async {
    if (_userId != null) {
      try {
        // Check if day has changed first (but don't call _checkDayChange recursively)
        final now = DateTime.now();
        if (_lastCheckedDate != null) {
          final lastDate = DateTime(
            _lastCheckedDate!.year,
            _lastCheckedDate!.month,
            _lastCheckedDate!.day,
          );
          final currentDate = DateTime(now.year, now.month, now.day);
          
          // If day has changed, save yesterday's data and reset
          if (currentDate.isAfter(lastDate)) {
            // Save yesterday's final progress to calendar history
            if (_completedSessionsToday > 0 || _totalStudyMinutesToday > 0) {
              await LocalStorageService.saveStudyHistoryForDate(
                userId: _userId!,
                date: _lastCheckedDate!,
                minutes: _totalStudyMinutesToday,
              );
            }
            
            // Reset today's counters
            _completedSessionsToday = 0;
            _totalStudyMinutesToday = 0;
            _currentSession = 1;
          }
        }
        
        // Load from Firestore (source of truth)
        final firestoreSessions = await _firestoreService.getTodaySessions(_userId!);
        
        // Calculate today's statistics from Firestore sessions
        _completedSessionsToday = firestoreSessions.length;
        _totalStudyMinutesToday = firestoreSessions.fold<int>(
          0,
          (sum, session) => sum + session.durationMinutes,
        );
        
        // Update last checked date
        _lastCheckedDate = now;
        
        // Sync to localStorage for offline access
        await LocalStorageService.saveProgress(
          userId: _userId!,
          currentStreak: 0, // Will be calculated separately
          totalSessions: _completedSessionsToday,
          totalMinutes: _totalStudyMinutesToday,
          lastStudyDate: now,
        );
        
        // Ensure today's data is saved to calendar history (both localStorage and Firestore)
        if (_totalStudyMinutesToday > 0) {
          await LocalStorageService.saveStudyHistoryForDate(
            userId: _userId!,
            date: now,
            minutes: _totalStudyMinutesToday,
          );
          
          // Save to Firestore calendar history (persists across logins)
          await _firestoreService.saveCalendarHistory(
            userId: _userId!,
            date: now,
            minutes: _totalStudyMinutesToday,
          );
        }
        
        notifyListeners();
      } catch (e) {
        // If Firestore fails, fallback to localStorage
        debugPrint('Error loading today statistics from Firestore: $e');
        _completedSessionsToday = await LocalStorageService.getTodaySessionCount(userId: _userId);
        _totalStudyMinutesToday = await LocalStorageService.getTodayStudyMinutes(userId: _userId);
        _lastCheckedDate = DateTime.now();
        notifyListeners();
      }
    }
  }
  
  // Refresh statistics
  Future<void> refreshStatistics() async {
    await _loadTodayStatistics();
  }

  // Save progress to database (Firestore + localStorage + Calendar History)
  Future<void> _saveProgressToDatabase() async {
    if (_userId == null) return;

    try {
      final today = DateTime.now();
      
      // Get current progress to maintain streak data
      final currentProgress = await LocalStorageService.getProgress(userId: _userId);
      final currentStreak = currentProgress['currentStreak'] ?? 0;
      
      // Calculate total sessions and minutes from Firestore (source of truth)
      final allSessions = await _firestoreService.getTodaySessions(_userId!);
      final todaySessions = allSessions.length;
      final todayMinutes = allSessions.fold<int>(
        0,
        (sum, session) => sum + session.durationMinutes,
      );
      
      // Update local counters to match Firestore
      _completedSessionsToday = todaySessions;
      _totalStudyMinutesToday = todayMinutes;
      
      // Save to localStorage for offline access
      await LocalStorageService.saveProgress(
        userId: _userId!,
        currentStreak: currentStreak,
        totalSessions: _completedSessionsToday,
        totalMinutes: _totalStudyMinutesToday,
        lastStudyDate: today,
      );
      
      // Save to calendar history (date-specific) - both localStorage and Firestore
      await LocalStorageService.saveStudyHistoryForDate(
        userId: _userId!,
        date: today,
        minutes: _totalStudyMinutesToday,
      );
      
      // Save to Firestore calendar history (persists across logins)
      await _firestoreService.saveCalendarHistory(
        userId: _userId!,
        date: today,
        minutes: _totalStudyMinutesToday,
      );
      
      // Save to Firestore progress document (real-time sync)
      await _firestoreService.updateUserProgress(
        userId: _userId!,
        totalSessions: _completedSessionsToday,
        totalMinutes: _totalStudyMinutesToday,
        lastStudyDate: today,
      );
      
      // Notify listeners of updated stats
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving progress to database: $e');
      // Silently fail - data is still in localStorage
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dayCheckTimer?.cancel();
    super.dispose();
  }
}
