import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/storage/local_storage_service.dart';
import '../../services/firebase/firestore_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  Map<String, int> _monthHistory = {};
  bool _isLoading = true;
  
  // Progress data
  int _currentStreak = 0;
  int _todaySessions = 0;
  int _todayMinutes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgressData();
      _loadMonthHistory();
    });
  }
  
  String? _lastUserId;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when user changes (login/logout)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    
    // If user ID changed (login/logout), reload data
    if (currentUserId != null && currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadProgressData();
      _loadMonthHistory();
    } else if (currentUserId == null && _lastUserId != null) {
      // User logged out
      _lastUserId = null;
      setState(() {
        _currentStreak = 0;
        _todaySessions = 0;
        _todayMinutes = 0;
        _monthHistory = {};
      });
    }
  }

  Future<void> _loadProgressData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    
    if (userId != null) {
      try {
        // Get today's statistics from TimerProvider (real-time, always accurate)
        final timerProvider = Provider.of<TimerProvider>(context, listen: false);
        final todaySessions = timerProvider.completedSessionsToday;
        final todayMinutes = timerProvider.totalStudyMinutesToday;
        
        // Get streak from PetProvider (source of truth for streaks)
        final petProvider = Provider.of<PetProvider>(context, listen: false);
        final currentStreak = petProvider.consecutiveDays;
        
        setState(() {
          _currentStreak = currentStreak;
          _todaySessions = todaySessions;
          _todayMinutes = todayMinutes;
        });
      } catch (e) {
        // If Firestore fails, use LocalStorage and TimerProvider
        final timerProvider = Provider.of<TimerProvider>(context, listen: false);
        final petProvider = Provider.of<PetProvider>(context, listen: false);
        await _loadFromLocalStorage(userId);
        setState(() {
          _currentStreak = petProvider.consecutiveDays;
          _todaySessions = timerProvider.completedSessionsToday;
          _todayMinutes = timerProvider.totalStudyMinutesToday;
        });
      }
    }
  }
  
  // Calculate current streak from calendar history
  int _calculateStreak(Map<String, int> currentMonth, Map<String, int> previousMonth) {
    final now = DateTime.now();
    final allHistory = {...currentMonth, ...previousMonth};
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    
    // Check consecutive days backwards from today
    while (true) {
      final dateKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      
      if (allHistory.containsKey(dateKey) && allHistory[dateKey]! > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
      
      // Limit to prevent infinite loop (check last 365 days)
      if (streak > 365) break;
    }
    
    return streak;
  }
  

  Future<void> _loadFromLocalStorage(String userId) async {
    final progress = await LocalStorageService.getProgress(userId: userId);
    final todaySessionCount = await LocalStorageService.getTodaySessionCount(userId: userId);
    final todayMinutes = await LocalStorageService.getTodayStudyMinutes(userId: userId);
    
    setState(() {
      _currentStreak = progress['currentStreak'] ?? 0;
      _todaySessions = todaySessionCount;
      _todayMinutes = todayMinutes;
    });
  }

  Future<void> _loadMonthHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    
    if (userId != null) {
      try {
        // Load from Firestore first (source of truth)
        final firestoreService = FirestoreService();
        final firestoreHistory = await firestoreService.getMonthCalendarHistory(
          userId: userId,
          year: _selectedMonth.year,
          month: _selectedMonth.month,
        );
        
        // Merge with localStorage (for offline access)
        final localHistory = await LocalStorageService.getMonthStudyHistory(
          userId: userId,
          year: _selectedMonth.year,
          month: _selectedMonth.month,
        );
        
        // Combine both sources (Firestore takes precedence)
        final combinedHistory = Map<String, int>.from(localHistory);
        combinedHistory.addAll(firestoreHistory);
        
        setState(() {
          _monthHistory = combinedHistory;
          _isLoading = false;
        });
      } catch (e) {
        // If Firestore fails, fallback to localStorage
        final history = await LocalStorageService.getMonthStudyHistory(
          userId: userId,
          year: _selectedMonth.year,
          month: _selectedMonth.month,
        );
        
        setState(() {
          _monthHistory = history;
          _isLoading = false;
        });
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _isLoading = true;
    });
    _loadMonthHistory();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 16.0;
    final verticalPadding = isTablet ? 24.0 : 20.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFE8E5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              _buildProfileCard(context),
              const SizedBox(height: 20),

              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Current Streak Card
              _buildStreakCard(),
              const SizedBox(height: 16),

              // Today's Progress Card
              _buildTodayProgressCard(),
              const SizedBox(height: 20),

              // Calendar Section
              _buildCalendarSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8B9FDE),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                      ? Image.network(
                          user.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B9FDE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.edit,
                      size: 18,
                      color: Color(0xFF8B9FDE),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user?.email ?? 'email@example.com',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap username to edit • Avatar to change photo',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF8B9FDE).withOpacity(0.2),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 35,
          color: Color(0xFF8B9FDE),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Progress',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Track your study journey',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        // Get real-time streak from PetProvider
        final currentStreak = petProvider.consecutiveDays;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B9FDE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFF8B9FDE),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Streak',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              // Current streak number (updates in real-time)
              Row(
                children: [
                  Text(
                    '$currentStreak',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B9FDE),
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'days in a row',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayProgressCard() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // Get real-time data from TimerProvider
        final sessions = timerProvider.completedSessionsToday;
        final minutes = timerProvider.totalStudyMinutesToday;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Progress',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$sessions',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B9FDE),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sessions',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$minutes',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B9FDE),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Minutes',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Study Calendar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Month navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                    color: const Color(0xFF8B9FDE),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                    color: const Color(0xFF8B9FDE),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Weekday headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((day) => SizedBox(
                          width: 40,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              // Calendar grid
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCalendarGrid(),
              // Selected date info
              if (_selectedDate != null) ...[
                const SizedBox(height: 20),
                _buildSelectedDateInfo(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final List<Widget> dayWidgets = [];

    // Empty spaces before first day
    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final minutes = _monthHistory[dateKey] ?? 0;
      final isToday = _isToday(date);
      final isSelected = _selectedDate != null && 
          date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;

      dayWidgets.add(_buildDayCell(date, minutes, isToday, isSelected));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(DateTime date, int minutes, bool isToday, bool isSelected) {
    final hasStudied = minutes > 0;
    final hours = minutes / 60;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B9FDE)
              : hasStudied
                  ? const Color(0xFF8B9FDE).withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: const Color(0xFF8B9FDE), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : hasStudied
                        ? const Color(0xFF374151)
                        : const Color(0xFF9CA3AF),
              ),
            ),
            if (hasStudied)
              Text(
                hours >= 1 ? '${hours.toStringAsFixed(1)}h' : '${minutes}m',
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateInfo() {
    if (_selectedDate == null) return const SizedBox();

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final minutes = _monthHistory[dateKey] ?? 0;
    final hours = minutes / 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B9FDE).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: Color(0xFF8B9FDE),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDate!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  minutes == 0
                      ? 'No study time recorded'
                      : hours >= 1
                          ? 'You studied ${hours.toStringAsFixed(1)} hours'
                          : 'You studied $minutes minutes',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
