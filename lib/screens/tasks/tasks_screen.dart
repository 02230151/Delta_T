import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import '../../services/notification_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  void _showEditTaskDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(task: task),
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

              // Add New Task Button
              _buildAddTaskButton(),
              const SizedBox(height: 16),

              // Tasks List
              Expanded(
                child: _buildTasksList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final taskCount = taskProvider.totalTasks;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Tasks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddTaskButton() {
    return InkWell(
      onTap: _showAddTaskDialog,
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
              'Add New Task',
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

  Widget _buildTasksList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B9FDE),
            ),
          );
        }

        if (taskProvider.tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: taskProvider.tasks.length,
          itemBuilder: (context, index) {
            final task = taskProvider.tasks[index];
            return _buildTaskItem(task);
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
              Icons.check_circle_outline,
              size: 40,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks yet',
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

  Widget _buildTaskItem(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              Provider.of<TaskProvider>(context, listen: false)
                  .toggleTaskCompletion(task);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? const Color(0xFF8B9FDE)
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? const Color(0xFF8B9FDE)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Task title
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                color: task.isCompleted
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF374151),
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          // Edit button
          IconButton(
            onPressed: () => _showEditTaskDialog(task),
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Color(0xFF64748B),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // Delete button
          IconButton(
            onPressed: () async {
              Provider.of<TaskProvider>(context, listen: false)
                  .deleteTask(task.id);
              // Show system notification instead of toast
              final notificationService = NotificationService();
              await notificationService.showNotification(
                id: DateTime.now().millisecondsSinceEpoch % 100000,
                title: 'Task Deleted',
                body: 'Task deleted successfully',
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
    );
  }
}

// Add Task Dialog
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    // Close dialog immediately before saving
    if (mounted) {
      Navigator.of(context).pop();
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.createTask(title: _taskController.text.trim());

    if (!mounted) return;

    // Show notification instead of toast
    final notificationService = NotificationService();
    await notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Task Created',
      body: 'Task created successfully!',
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
                  'Add New Task',
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
              'Create a new task to add to your to-do list',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            // Task input
            const Text(
              'Task',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter Task',
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
              onSubmitted: (_) => _addTask(),
            ),
            const SizedBox(height: 20),
            // Add button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B9FDE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Task',
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

// Edit Task Dialog
class EditTaskDialog extends StatefulWidget {
  final TaskModel task;

  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late TextEditingController _taskController;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.task.title);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _updateTask() async {
    if (_taskController.text.trim().isEmpty) return;

    // Close dialog immediately before saving
    if (mounted) {
      Navigator.of(context).pop();
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final updatedTask = widget.task.copyWith(
      title: _taskController.text.trim(),
    );
    await taskProvider.updateTask(updatedTask);

    if (!mounted) return;

    // Show notification instead of toast
    final notificationService = NotificationService();
    await notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Task Updated',
      body: 'Task updated successfully!',
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
                  'Edit Task',
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
              'Update your task details',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            // Task input
            const Text(
              'Task',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter task name',
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
              onSubmitted: (_) => _updateTask(),
            ),
            const SizedBox(height: 20),
            // Update button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _updateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B9FDE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Update Task',
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
