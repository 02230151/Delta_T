import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_provider.dart';
import '../settings/settings_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Set up toast callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      timerProvider.onShowToast = (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      };
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 16.0;
    final verticalPadding = isTablet ? 24.0 : 20.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: SafeArea(
        child: Consumer<TimerProvider>(
          builder: (context, timerProvider, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),
                  
                  // Timer Mode Card
                  _buildTimerModeCard(),
                  const SizedBox(height: 16),
                  
                  // Main Timer Card
                  _buildMainTimerCard(),
                  const SizedBox(height: 16),
                  
                  // Sessions Completed Card
                  _buildSessionsCard(),
                  
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Delta T',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            Text(
              'Pomodoro Timer',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const SettingsScreen(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimerModeCard() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final isPomodoro = timerProvider.timerMode == TimerMode.pomodoro;
        
        return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Timer Mode',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Pomodoro',
                    style: TextStyle(
                      color: isPomodoro ? Color(0xFF8B9FDE) : Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: isPomodoro ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: !isPomodoro,
                    onChanged: (v) {
                      timerProvider.setTimerMode(
                        v ? TimerMode.standard : TimerMode.pomodoro
                      );
                    },
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF8B9FDE),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF8B9FDE),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Standard',
                    style: TextStyle(
                      color: !isPomodoro ? Color(0xFF8B9FDE) : Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: !isPomodoro ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildMainTimerCard() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final isPomodoro = timerProvider.timerMode == TimerMode.pomodoro;
        final isRunning = timerProvider.isRunning;
        final isPaused = timerProvider.timerState == TimerState.paused;
        
        return Container(
          padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B9FDE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timerProvider.isBreakTime ? 'Break Time' : (isPomodoro ? 'Study Time' : 'Focus Timer'),
                  style: const TextStyle(
                    color: Color(0xFF8B9FDE),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatTime(timerProvider.remainingTime),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPomodoro ? 'Session #${timerProvider.currentSession}' : '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: () {
                      if (isRunning) {
                        timerProvider.pauseTimer();
                      } else if (isPaused) {
                        timerProvider.resumeTimer();
                      } else {
                        timerProvider.startTimer();
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B9FDE),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B9FDE).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Stop button (for standard mode) or Reset button (for pomodoro)
                  GestureDetector(
                    onTap: () async {
                      if (!isPomodoro && isRunning) {
                        // Standard mode: stop and save
                        await timerProvider.stopTimer();
                      } else {
                        // Pomodoro mode: reset
                        timerProvider.resetTimer();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        (!isPomodoro && isRunning) ? Icons.stop : Icons.refresh,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
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

  Widget _buildSessionsCard() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Total Study Time Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${timerProvider.totalStudyMinutesToday} min',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B9FDE),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
