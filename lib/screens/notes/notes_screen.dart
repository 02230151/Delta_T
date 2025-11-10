import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/note_provider.dart';
import '../../models/note_model.dart';
import '../../services/notification_service.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddNoteDialog(),
    );
  }

  void _showEditNoteDialog(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => EditNoteDialog(note: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Add New Note Button
              _buildAddNoteButton(context),
              const SizedBox(height: 16),

              // Notes List
              Expanded(
                child: _buildNotesList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Write down your thoughts',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAddNoteButton(BuildContext context) {
    return InkWell(
      onTap: () => _showAddNoteDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF8B9FDE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Add New Note',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        if (noteProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B9FDE),
            ),
          );
        }

        if (noteProvider.notes.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: noteProvider.notes.length,
          itemBuilder: (context, index) {
            final note = noteProvider.notes[index];
            return _buildNoteCard(context, note);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.note_outlined,
              size: 40,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteModel note) {
    final dateFormat = DateFormat('MMM dd, h:mm a');
    final formattedDate = dateFormat.format(note.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and actions row
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showEditNoteDialog(context, note),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () async {
                  Provider.of<NoteProvider>(context, listen: false)
                      .deleteNote(note.id);
                  // Show system notification instead of toast
                  final notificationService = NotificationService();
                  await notificationService.showNotification(
                    id: DateTime.now().millisecondsSinceEpoch % 100000,
                    title: 'Note Deleted',
                    body: 'Note deleted successfully',
                  );
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Content
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Date
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add Note Dialog
class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addNote() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      return;
    }

    // Close dialog immediately before saving
    if (mounted) {
      Navigator.of(context).pop();
    }

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    await noteProvider.createNote(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );

    if (!mounted) return;

    // Show notification instead of toast
    final notificationService = NotificationService();
    await notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Note Created',
      body: 'Note created successfully!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF6B7280),
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new note to capture your thoughts and ideas',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            // Title input
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter note title',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Content input
            const Text(
              'Content',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your thoughts...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Add button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _addNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B9FDE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Note',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Edit Note Dialog
class EditNoteDialog extends StatefulWidget {
  final NoteModel note;

  const EditNoteDialog({super.key, required this.note});

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateNote() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      return;
    }

    // Close dialog immediately before saving
    if (mounted) {
      Navigator.of(context).pop();
    }

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final updatedNote = widget.note.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );
    await noteProvider.updateNote(updatedNote);

    if (!mounted) return;

    // Show notification instead of toast
    final notificationService = NotificationService();
    await notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Note Updated',
      body: 'Note updated successfully!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF6B7280),
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Update your note content and title',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            // Title input
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter note title',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Content input
            const Text(
              'Content',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your thoughts...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B9FDE),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Update button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _updateNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B9FDE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Update Note',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
