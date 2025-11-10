import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/storage/local_storage_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _userId;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;
  
  // Callback for showing toast messages
  Function(String message)? onShowToast;
  
  // Callback for achievement unlocked
  Function(String achievement)? onAchievementUnlocked;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  
  // Check if there are no tasks (empty state)
  bool get isEmpty => _tasks.isEmpty;

  // Initialize with user ID and start listening
  void initialize(String userId) {
    _userId = userId;
    _listenToTasks();
  }

  // Listen to task changes
  void _listenToTasks() async {
    if (_userId != null) {
      _isLoading = true;
      notifyListeners();

      // Load from localStorage first for immediate display
      await _loadTasksFromLocalStorage();

      // Cancel existing subscription if any
      _tasksSubscription?.cancel();

      // Then listen to Firestore for real-time updates
      _tasksSubscription = _firestoreService.getUserTasks(_userId!).listen((tasks) {
        _tasks = tasks;
        _isLoading = false;
        notifyListeners();
        
        // Sync to localStorage
        _syncTasksToLocalStorage();
      });
    }
  }

  // Load tasks from localStorage
  Future<void> _loadTasksFromLocalStorage() async {
    if (_userId != null) {
      final tasksData = await LocalStorageService.getUserTasks(_userId!);
      _tasks = tasksData.map((data) => TaskModel.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sync tasks to localStorage
  Future<void> _syncTasksToLocalStorage() async {
    if (_userId != null) {
      for (var task in _tasks) {
        await LocalStorageService.saveTask(
          taskId: task.id,
          userId: task.userId,
          title: task.title,
          description: task.description,
          isCompleted: task.isCompleted,
          createdAt: task.createdAt,
          completedAt: task.completedAt,
        );
      }
    }
  }

  // Create task
  Future<void> createTask({
    required String title,
    String? description,
  }) async {
    if (_userId == null) return;

    final task = TaskModel(
      id: const Uuid().v4(),
      userId: _userId!,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    await _firestoreService.createTask(task);
    
    // Save to localStorage
    await LocalStorageService.saveTask(
      taskId: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
    );
    
    // Show success toast
    onShowToast?.call('Task added successfully! ✅');
  }

  // Update task
  Future<void> updateTask(TaskModel task) async {
    // Update in Firestore
    await _firestoreService.updateTask(task);
    
    // Update in localStorage
    await LocalStorageService.saveTask(
      taskId: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
    );
    
    // Show success toast
    onShowToast?.call('Task updated! 📝');
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(TaskModel task) async {
    final wasCompleted = task.isCompleted;
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    
    await updateTask(updatedTask);
    
    // Show appropriate toast
    if (!wasCompleted) {
      onShowToast?.call('Task completed! Great job! 🎉');
      
      // Check for Task Master achievement (10+ completed tasks)
      if (_userId != null) {
        final hasAchievement = await LocalStorageService.hasTaskMasterAchievement(_userId!);
        if (hasAchievement) {
          onAchievementUnlocked?.call('Task Master - Completed 10+ tasks! 🏆');
        }
      }
    } else {
      onShowToast?.call('Task marked as incomplete');
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    // Delete from Firestore
    await _firestoreService.deleteTask(taskId);
    
    // Delete from localStorage
    await LocalStorageService.deleteTask(taskId);
    
    // Show success toast
    onShowToast?.call('Task deleted! 🗑️');
  }

  // Get task statistics
  Future<Map<String, int>> getStatistics() async {
    if (_userId == null) {
      return {'total': 0, 'completed': 0, 'pending': 0};
    }
    
    // Get from localStorage for immediate access
    final localStats = await LocalStorageService.getTaskStatistics(_userId!);
    
    // Also get from Firestore (more reliable)
    final firestoreStats = await _firestoreService.getTaskStatistics(_userId!);
    
    // Return Firestore stats if available, otherwise localStorage
    return firestoreStats['total']! > 0 ? firestoreStats : localStats;
  }
  
  // Refresh tasks from both sources
  Future<void> refresh() async {
    await _loadTasksFromLocalStorage();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
