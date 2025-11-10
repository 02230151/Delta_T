import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/timer_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _studyTime;
  late int _breakTime;
  late bool _soundNotifications;
  late TextEditingController _studyController;
  late TextEditingController _breakController;

  @override
  void initState() {
    super.initState();
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _studyTime = timerProvider.studyTime;
    _breakTime = timerProvider.breakTime;
    _soundNotifications = timerProvider.soundNotifications;
    _studyController = TextEditingController(text: _studyTime.toString());
    _breakController = TextEditingController(text: _breakTime.toString());
  }

  @override
  void dispose() {
    _studyController.dispose();
    _breakController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.updateSettings(
      studyTime: _studyTime,
      breakTime: _breakTime,
      soundNotifications: _soundNotifications,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Close the dialog
    Navigator.pop(context);
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customize your study sessions and app preferences',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Timer Settings Card
                    _buildTimerSettingsCard(),
                    const SizedBox(height: 16),
                    
                    // Notifications Card
                    _buildNotificationsCard(),
                    const SizedBox(height: 20),
                    
                    // Save Settings Button
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                    
                    // Sign Out Section
                    _buildSignOutSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSettingsCard() {
    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Color(0xFF8B9FDE),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Timer Settings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Study Time
          _buildTimeSetting(
            'Study Time (minutes)',
            _studyController,
            (value) => setState(() => _studyTime = value),
            1,
            120,
          ),
          const SizedBox(height: 16),
          
          // Break Time
          _buildTimeSetting(
            'Break Time (minutes)',
            _breakController,
            (value) => setState(() => _breakTime = value),
            1,
            60,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSetting(
    String title,
    TextEditingController controller,
    ValueChanged<int> onChanged,
    int min,
    int max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B9FDE), width: 2),
            ),
            suffixText: 'min',
            suffixStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (text) {
            final newValue = int.tryParse(text);
            if (newValue != null && newValue >= min && newValue <= max) {
              onChanged(newValue);
            }
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Enter value between $min-$max minutes',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF8B9FDE),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sound Notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Play sounds when timer completes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _soundNotifications,
                onChanged: (value) => setState(() => _soundNotifications = value),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF8B9FDE),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B9FDE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Save Settings',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign out of your Delta T account',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(
                Icons.logout,
                size: 18,
              ),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
