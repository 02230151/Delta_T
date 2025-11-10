import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/storage/local_storage_service.dart';

class NoteProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _userId;
  StreamSubscription<List<NoteModel>>? _notesSubscription;

  // Callback for toast notifications
  Function(String message)? onShowToast;

  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  int get totalNotes => _notes.length;
  bool get isEmpty => _notes.isEmpty;

  // Initialize with user ID and start listening
  void initialize(String userId) async {
    _userId = userId;
    await _loadNotesFromLocalStorage();
    _listenToNotes();
  }

  // Load notes from localStorage first (instant display)
  Future<void> _loadNotesFromLocalStorage() async {
    if (_userId == null) return;
    
    final notesData = await LocalStorageService.getUserNotes(_userId!);
    _notes = notesData.map((data) => NoteModel.fromMap(data)).toList();
    notifyListeners();
  }

  // Listen to note changes from Firestore
  void _listenToNotes() {
    if (_userId != null) {
      // Cancel existing subscription if any
      _notesSubscription?.cancel();
      
      _isLoading = true;
      notifyListeners();

      _notesSubscription = _firestoreService.getUserNotes(_userId!).listen((notes) async {
        _notes = notes;
        _isLoading = false;
        notifyListeners();
        
        // Sync to localStorage (batch operation for better performance)
        for (var note in notes) {
          await LocalStorageService.saveNote(
            noteId: note.id,
            userId: note.userId,
            title: note.title,
            content: note.content,
            createdAt: note.createdAt,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }

  // Create note
  Future<void> createNote({
    required String title,
    required String content,
  }) async {
    if (_userId == null) return;

    final note = NoteModel(
      id: const Uuid().v4(),
      userId: _userId!,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore
    await _firestoreService.createNote(note);
    
    // Save to localStorage
    await LocalStorageService.saveNote(
      noteId: note.id,
      userId: note.userId,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
    );
    
    // Show success toast
    onShowToast?.call('📝 Note added successfully!');
  }

  // Update note
  Future<void> updateNote(NoteModel note) async {
    final updatedNote = note.copyWith(
      updatedAt: DateTime.now(),
    );
    
    // Update in Firestore
    await _firestoreService.updateNote(updatedNote);
    
    // Update in localStorage
    await LocalStorageService.saveNote(
      noteId: updatedNote.id,
      userId: updatedNote.userId,
      title: updatedNote.title,
      content: updatedNote.content,
      createdAt: updatedNote.createdAt,
    );
    
    // Show success toast
    onShowToast?.call('✏️ Note updated!');
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    // Delete from Firestore
    await _firestoreService.deleteNote(noteId);
    
    // Delete from localStorage
    await LocalStorageService.deleteNote(noteId);
    
    // Show success toast
    onShowToast?.call('🗑️ Note deleted!');
  }

  // Search notes
  List<NoteModel> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    
    final lowercaseQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
          note.content.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Format date as "Jan 15, 2:30 PM"
  String formatNoteDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final month = months[date.month - 1];
    final day = date.day;
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $hour:$minute $period';
  }

  // Refresh notes
  Future<void> refresh() async {
    await _loadNotesFromLocalStorage();
  }
}
