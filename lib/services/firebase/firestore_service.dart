import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/note_model.dart';
import '../../models/study_session_model.dart';
import '../../models/pet_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== USER OPERATIONS ==========

  // Create user
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toMap());
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .update(user.toMap());
  }

  // ========== TASK OPERATIONS ==========

  // Create task
  Future<void> createTask(TaskModel task) async {
    await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(task.id)
        .set(task.toMap());
  }

  // Get tasks for user
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection(AppConstants.tasksCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data()))
            .toList());
  }

  // Update task
  Future<void> updateTask(TaskModel task) async {
    await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(task.id)
        .update(task.toMap());
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(AppConstants.tasksCollection).doc(taskId).delete();
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.tasksCollection)
        .where('userId', isEqualTo: userId)
        .get();

    int total = snapshot.docs.length;
    int completed = snapshot.docs.where((doc) => doc.data()['isCompleted'] == true).length;

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
    };
  }

  // ========== NOTE OPERATIONS ==========

  // Create note
  Future<void> createNote(NoteModel note) async {
    await _firestore
        .collection(AppConstants.notesCollection)
        .doc(note.id)
        .set(note.toMap());
  }

  // Get notes for user
  Stream<List<NoteModel>> getUserNotes(String userId) {
    return _firestore
        .collection(AppConstants.notesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromMap(doc.data()))
            .toList());
  }

  // Update note
  Future<void> updateNote(NoteModel note) async {
    await _firestore
        .collection(AppConstants.notesCollection)
        .doc(note.id)
        .update(note.toMap());
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    await _firestore.collection(AppConstants.notesCollection).doc(noteId).delete();
  }

  // ========== SESSION OPERATIONS ==========

  // Create study session
  Future<void> createStudySession(StudySessionModel session) async {
    await _firestore
        .collection(AppConstants.sessionsCollection)
        .doc(session.id)
        .set(session.toMap());
  }

  // Get today's sessions
  Future<List<StudySessionModel>> getTodaySessions(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // Query sessions from last 7 days only (optimization - reduces data fetched)
    // Then filter by today in memory
    final weekAgo = startOfDay.subtract(const Duration(days: 7));
    final snapshot = await _firestore
        .collection(AppConstants.sessionsCollection)
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: weekAgo.toIso8601String())
        .orderBy('startTime', descending: true)
        .limit(100) // Limit to 100 most recent sessions
        .get();

    // Filter sessions that started today
    final todaySessions = snapshot.docs
        .map((doc) {
          try {
            return StudySessionModel.fromMap(doc.data());
          } catch (e) {
            return null;
          }
        })
        .where((session) => session != null)
        .cast<StudySessionModel>()
        .where((session) {
          final sessionDate = DateTime(
            session.startTime.year,
            session.startTime.month,
            session.startTime.day,
          );
          final todayDate = DateTime(now.year, now.month, now.day);
          return sessionDate.isAtSameMomentAs(todayDate);
        })
        .toList();

    return todaySessions;
  }

  // Get study statistics for date range
  Future<Map<String, dynamic>> getStudyStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection(AppConstants.sessionsCollection)
        .where('userId', isEqualTo: userId)
        .where('startTime',
            isGreaterThanOrEqualTo: startDate.toIso8601String())
        .orderBy('startTime')
        .get();

    // Filter by end date in memory since Firestore doesn't support multiple range queries
    final filteredDocs = snapshot.docs.where((doc) {
      final startTime = DateTime.parse(doc.data()['startTime'] as String);
      return startTime.isBefore(endDate) || startTime.isAtSameMomentAs(endDate);
    }).toList();

    int totalMinutes = 0;
    int sessionCount = filteredDocs.length;

    for (var doc in filteredDocs) {
      totalMinutes += (doc.data()['durationMinutes'] as int? ?? 0);
    }

    return {
      'totalMinutes': totalMinutes,
      'sessionCount': sessionCount,
      'averageMinutes': sessionCount > 0 ? totalMinutes ~/ sessionCount : 0,
    };
  }

  // ========== PET OPERATIONS ==========

  // Create pet
  Future<void> createPet(PetModel pet) async {
    await _firestore
        .collection(AppConstants.petsCollection)
        .doc(pet.id)
        .set(pet.toMap());
  }

  // Get pet for user
  Future<PetModel?> getUserPet(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.petsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    
    return PetModel.fromMap(snapshot.docs.first.data());
  }

  // Update pet
  Future<void> updatePet(PetModel pet) async {
    await _firestore
        .collection(AppConstants.petsCollection)
        .doc(pet.id)
        .update(pet.toMap());
  }

  // ========== PROGRESS OPERATIONS ==========

  // Update user progress (real-time sync)
  Future<void> updateUserProgress({
    required String userId,
    required int totalSessions,
    required int totalMinutes,
    required DateTime lastStudyDate,
  }) async {
    await _firestore
        .collection('progress')
        .doc(userId)
        .set({
      'userId': userId,
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'lastStudyDate': Timestamp.fromDate(lastStudyDate),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user progress
  Future<Map<String, dynamic>?> getUserProgress(String userId) async {
    final doc = await _firestore
        .collection('progress')
        .doc(userId)
        .get();
    
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Stream user progress (real-time updates)
  Stream<Map<String, dynamic>?> streamUserProgress(String userId) {
    return _firestore
        .collection('progress')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // Save calendar history for a specific date
  Future<void> saveCalendarHistory({
    required String userId,
    required DateTime date,
    required int minutes,
  }) async {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    await _firestore
        .collection('calendar_history')
        .doc('${userId}_$dateKey')
        .set({
      'userId': userId,
      'date': dateKey,
      'minutes': minutes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get calendar history for a month
  Future<Map<String, int>> getMonthCalendarHistory({
    required String userId,
    required int year,
    required int month,
  }) async {
    final startDate = '${year}-${month.toString().padLeft(2, '0')}-01';
    final endDate = '${year}-${month.toString().padLeft(2, '0')}-31';
    
    final snapshot = await _firestore
        .collection('calendar_history')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    final monthData = <String, int>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateKey = data['date'] as String? ?? '';
      final minutes = data['minutes'] as int? ?? 0;
      if (dateKey.isNotEmpty && minutes > 0) {
        monthData[dateKey] = minutes;
      }
    }

    return monthData;
  }

  // Get all calendar history for user (for calendar view)
  Future<Map<String, int>> getAllCalendarHistory(String userId) async {
    final snapshot = await _firestore
        .collection('calendar_history')
        .where('userId', isEqualTo: userId)
        .get();

    final history = <String, int>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateKey = data['date'] as String? ?? '';
      final minutes = data['minutes'] as int? ?? 0;
      if (dateKey.isNotEmpty && minutes > 0) {
        history[dateKey] = minutes;
      }
    }

    return history;
  }
}
