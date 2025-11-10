import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/pet_provider.dart';
import '../auth/login_screen.dart';
import '../timer/timer_screen.dart';
import '../tasks/tasks_screen.dart';
import '../progress/progress_screen.dart';
import '../notes/notes_screen.dart';
import '../pet/pet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      
      timerProvider.initialize(userId);
      Provider.of<TaskProvider>(context, listen: false).initialize(userId);
      Provider.of<NoteProvider>(context, listen: false).initialize(userId);
      petProvider.initialize(userId);
      
      // Connect timer to pet - when session completes, update pet streak
      timerProvider.onSessionComplete = () {
        petProvider.recordStudySession();
      };
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TimerScreen(),
      const TasksScreen(),
      const ProgressScreen(),
      const NotesScreen(),
      const PetScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            activeIcon: Icon(Icons.check_box),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Pet',
          ),
        ],
      ),
    );
  }
}

// Placeholder pages (will be built in next phase)

class _TasksPage extends StatefulWidget {
  @override
  State<_TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<_TasksPage> {
  final List<_Task> _tasks = <_Task>[
    _Task(title: 'Complete math homework'),
    _Task(title: 'Read history chapter', completed: true),
  ];

  void _showTaskSheet({int? editIndex}) {
    final isEdit = editIndex != null;
    final controller = TextEditingController(
      text: isEdit ? _tasks[editIndex].title : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Task' : 'Add New Task',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Task title',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    setState(() {
                      if (isEdit) {
                        _tasks[editIndex!] =
                            _tasks[editIndex].copyWith(title: text);
                      } else {
                        _tasks.insert(0, _Task(title: text));
                      }
                    });
                    Navigator.pop(ctx);
                    if (!isEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task created')),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4ECF6),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskSheet(),
        backgroundColor: const Color(0xFF1F3A63),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Tasks',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${_tasks.length} tasks',
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7A90))),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _TaskTile(
                      task: task,
                      onChanged: (v) {
                        setState(() {
                          _tasks[index] = task.copyWith(completed: v);
                        });
                      },
                      onEdit: () => _showTaskSheet(editIndex: index),
                      onDelete: () {
                        setState(() {
                          _tasks.removeAt(index);
                        });
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _tasks.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final _Task task;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.completed,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                decoration:
                    task.completed ? TextDecoration.lineThrough : TextDecoration.none,
                color: const Color(0xFF1F3A63),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              child: Text(task.title, overflow: TextOverflow.ellipsis),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _Task {
  final String title;
  final bool completed;

  _Task({required this.title, this.completed = false});

  _Task copyWith({String? title, bool? completed}) =>
      _Task(title: title ?? this.title, completed: completed ?? this.completed);
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  final String number;
  final String label;
  const _Metric({required this.number, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF6B7A90))),
      ],
    );
  }
}

class _Achievement extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool locked;
  const _Achievement._({required this.title, required this.subtitle, required this.locked});
  const _Achievement.locked({required String title, required String subtitle})
      : this._(title: title, subtitle: subtitle, locked: true);
  @override
  Widget build(BuildContext context) {
    final bg = locked ? const Color(0xFFF1F4FA) : Colors.white;
    final border = locked ? const Color(0xFFE1E6F0) : const Color(0xFFD7DEEA);
    final icon = locked ? Icons.lock_outline : Icons.emoji_events_outlined;
    final iconColor = locked ? const Color(0xFF9AA7BD) : Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                locked ? 'Locked' : 'Unlocked',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7A90)),
              ),
            )
          ]),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
        ],
      ),
    );
  }
}

class _DotCalendar extends StatelessWidget {
  const _DotCalendar();
  @override
  Widget build(BuildContext context) {
    // Static 5 weeks x 7 days with some filled dots
    const filled = {
      1, 2, 4, 6, 9, 10, 12, 15, 16, 20, 22, 25
    }; // arbitrary for demo UI
    return Column(
      children: List.generate(5, (week) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (day) {
              final idx = week * 7 + day + 1;
              final active = filled.contains(idx);
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1F3A63) : const Color(0xFFD7DEEA),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _NotesPage extends StatefulWidget {
  @override
  State<_NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<_NotesPage> {
  final List<_Note> _notes = <_Note>[
    _Note(
      title: 'Great focus session!',
      content:
          'Had an amazing study session today. The Pomodoro technique really helps me stay focused. I managed to complete 4 sessions in a row.',
      createdAt: DateTime.now(),
    ),
  ];

  void _openNoteDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final titleController = TextEditingController(
      text: isEdit ? _notes[editIndex!].title : '',
    );
    final contentController = TextEditingController(
      text: isEdit ? _notes[editIndex!].content : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Note' : 'Add New Note',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isEdit
                      ? 'Update your note content and title'
                      : 'Create a new note to capture your thoughts and ideas',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF6B7A90)),
                ),
                const SizedBox(height: 12),
                const Text('Title'),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter note title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                const Text('Content'),
                const SizedBox(height: 6),
                TextField(
                  controller: contentController,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Write your thoughts...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      if (title.isEmpty || content.isEmpty) return;
                      setState(() {
                        if (isEdit) {
                          _notes[editIndex!] = _notes[editIndex]
                              .copyWith(title: title, content: content);
                        } else {
                          _notes.insert(
                            0,
                            _Note(title: title, content: content, createdAt: DateTime.now()),
                          );
                        }
                      });
                      Navigator.pop(ctx);
                      if (!isEdit) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note added')),
                        );
                      }
                    },
                    child: Text(isEdit ? 'Update Note' : 'Add Note'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4ECF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notes',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Write down your thoughts',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFF6B7A90))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openNoteDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Note'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1F3A63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return _NoteCard(
                      note: note,
                      onEdit: () => _openNoteDialog(editIndex: index),
                      onDelete: () {
                        setState(() {
                          _notes.removeAt(index);
                        });
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _notes.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final _Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _NoteCard({required this.note, required this.onEdit, required this.onDelete});

  String _formatDate(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return 'Oct ${two(dt.day)}, ${two(dt.hour)}:${two(dt.minute)} ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      )),
                ),
                Row(children: [
                  IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
                ])
              ],
            ),
            const SizedBox(height: 8),
            Text(note.content),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7A90)),
                const SizedBox(width: 6),
                Text(_formatDate(note.createdAt),
                    style:
                        const TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Note {
  final String title;
  final String content;
  final DateTime createdAt;

  _Note({required this.title, required this.content, required this.createdAt});

  _Note copyWith({String? title, String? content}) => _Note(
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt,
      );
}

class _ProgressPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE4ECF6);
    const dark = Color(0xFF1F3A63);
    const gray = Color(0xFF6B7A90);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Progress',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Track your study journey',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: gray)),
              const SizedBox(height: 16),

              // Current Streak card
              _Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.local_fire_department_outlined, color: dark),
                      SizedBox(width: 8),
                      Text('Current Streak',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 2),
                    Text('5',
                        style:
                            TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    Text('days in a row', style: TextStyle(color: gray)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Today's Progress
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Today\'s Progress',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Icon(Icons.calendar_today_outlined, color: gray, size: 18),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Metric(number: '3', label: 'Pomodoros'),
                        const SizedBox(width: 24),
                        _Metric(number: '85', label: 'Minutes'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Coming Up
              Text('Coming Up',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(child: _Achievement.locked(title: 'Century Club', subtitle: 'Complete 100\nPomodoro sessions')),
                        SizedBox(width: 12),
                        Expanded(child: _Achievement.locked(title: 'Task Master', subtitle: 'Complete 10 tasks')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(child: _Achievement.locked(title: 'Night Owl', subtitle: 'Study after 10 PM')),
                        SizedBox(width: 12),
                        Expanded(child: _Achievement.locked(title: 'Early Bird', subtitle: 'Study before 7 AM')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Calendar with dots
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('This Month',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    _DotCalendar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4ECF6),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE4ECF6), Color(0xFFDDE7F4)],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: const [
                    Text(
                      'Your focus tree grows as you study each day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF1F3A63)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Keep your streak to help it flourish.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF1F3A63)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Center tree illustration (placeholder emoji)
              const Text('🌳', style: TextStyle(fontSize: 120)),
              const SizedBox(height: 8),
              const Text('Day 28', style: TextStyle(color: Color(0xFF1F3A63))),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
