import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pet_model.dart';
import '../services/firebase/firestore_service.dart';

class PetProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  PetModel? _pet;
  bool _isLoading = false;
  String? _userId;

  PetModel? get pet => _pet;
  bool get isLoading => _isLoading;
  bool get hasPet => _pet != null;
  int get consecutiveDays => _pet?.consecutiveDays ?? 0;
  int get growthStage => _pet?.growthStage ?? 0;
  String get treeEmoji => _pet?.treeEmoji ?? '🌰';
  int get backgroundTreeCount => _pet?.backgroundTreeCount ?? 0;

  // Initialize with user ID
  void initialize(String userId) {
    _userId = userId;
    _loadPet();
  }

  // Load pet from Firestore
  Future<void> _loadPet() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _pet = await _firestoreService.getUserPet(_userId!);
      
      // Create new pet if doesn't exist
      if (_pet == null) {
        await _createNewPet();
      } else {
        // Check if streak should reset
        if (_pet!.shouldResetStreak()) {
          await _resetStreak();
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading pet: $e');
    }
  }

  // Create new pet
  Future<void> _createNewPet() async {
    if (_userId == null) return;

    final newPet = PetModel(
      id: const Uuid().v4(),
      userId: _userId!,
      consecutiveDays: 0,
      lastStudyDate: null,
      totalSessions: 0,
    );

    await _firestoreService.createPet(newPet);
    _pet = newPet;
    notifyListeners();
  }

  // Record a completed study session
  Future<void> recordStudySession() async {
    if (_pet == null || _userId == null) {
      debugPrint('❌ Cannot record session: pet=${_pet == null}, userId=${_userId == null}');
      return;
    }

    try {
      final now = DateTime.now();
      debugPrint(' Recording study session at ${now.toString()}');
      debugPrint('   Current streak: ${_pet!.consecutiveDays}, Last study: ${_pet!.lastStudyDate}');
      
      // Check if already studied in current "day" (same minute in testing, same day in real)
      if (_pet!.hasStudiedToday()) {
        debugPrint('   ⚠️ Already studied in this "day" - only incrementing total sessions');
        // Just increment total sessions, don't change streak
        final updatedPet = _pet!.copyWith(
          totalSessions: _pet!.totalSessions + 1,
        );
        await _firestoreService.updatePet(updatedPet);
        _pet = updatedPet;
        notifyListeners();
        return;
      }

      // Calculate new streak based on consecutive days logic
      int newConsecutiveDays;
      
      if (_pet!.lastStudyDate == null) {
        // First session ever - start streak at 0 (Seed stage, Day 1)
        newConsecutiveDays = 0;
        debugPrint(' First session ever - starting streak at 0 (Seed, Day 1)');
      } else if (_pet!.isConsecutiveDay(now)) {
        // Next consecutive "day" - increment streak
        newConsecutiveDays = _pet!.consecutiveDays + 1;
        debugPrint(' Consecutive "day" - incrementing streak to $newConsecutiveDays');
      } else {
        // More than 1 "day" skipped - reset streak to 0 (since we're studying now, but streak is broken)
        newConsecutiveDays = 0;
        final daysDiff = PetModel.getTimeDifferenceInDays(now, _pet!.lastStudyDate!);
        debugPrint('  Gap of $daysDiff "days" - resetting streak to 0 (Seed, Day 1)');
      }

      final updatedPet = _pet!.copyWith(
        consecutiveDays: newConsecutiveDays,
        lastStudyDate: now,
        totalSessions: _pet!.totalSessions + 1,
      );

      await _firestoreService.updatePet(updatedPet);
      _pet = updatedPet;
      notifyListeners();
      
      debugPrint(' Streak updated: $newConsecutiveDays days → Stage ${updatedPet.growthStage} (${updatedPet.treeEmoji})');
    } catch (e) {
      debugPrint(' Error recording study session: $e');
    }
  }

  // Reset streak (called when streak is broken - more than 1 "day" passed)
  Future<void> _resetStreak() async {
    if (_pet == null) return;

    try {
      final updatedPet = _pet!.copyWith(
        consecutiveDays: 0, // Reset to 0 since no session today
        // Keep lastStudyDate to track when streak was broken
      );

      await _firestoreService.updatePet(updatedPet);
      _pet = updatedPet;
      notifyListeners();
      debugPrint('Streak reset to 0 (more than 1 day passed without study)');
    } catch (e) {
      debugPrint('Error resetting streak: $e');
    }
  }

  // Get pet statistics
  Map<String, dynamic> getStatistics() {
    if (_pet == null) {
      return {
        'consecutiveDays': 0,
        'growthStage': 0,
        'stageName': 'Seed',
        'totalSessions': 0,
        'backgroundTrees': 0,
      };
    }

    return {
      'consecutiveDays': _pet!.consecutiveDays,
      'growthStage': _pet!.growthStage,
      'stageName': _pet!.stageName,
      'totalSessions': _pet!.totalSessions,
      'backgroundTrees': _pet!.backgroundTreeCount,
    };
  }

  // Refresh pet data
  Future<void> refresh() async {
    await _loadPet();
  }
}
