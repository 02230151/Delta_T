import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait for auth initialization to complete
    // Give it time to check Firebase Auth and localStorage
    int attempts = 0;
    while (authProvider.isLoading && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    
    // Add a small delay to ensure everything is settled
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    debugPrint('Splash screen check: isAuthenticated=${authProvider.isAuthenticated}');
    
    if (authProvider.isAuthenticated) {
      debugPrint(' User authenticated - navigating to HomeScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      debugPrint(' User not authenticated - navigating to LoginScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large Clock Icon (like first splash screen)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A5F7F), // Muted blue background
                border: Border.all(
                  color: const Color(0xFFE8D5B7), // Light beige/off-white border
                  width: 18,
                ),
              ),
              child: CustomPaint(
                size: const Size(200, 200),
                painter: ClockPainter(),
              ),
            ),
            const SizedBox(height: 40),
            // App Name
            const Text(
              'Delta T',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5F7F),
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            const Text(
              'Your Study Companion',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 60),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A5F7F)),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for clock hands
class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Hour hand (shorter, thicker, pointing to 9 o'clock)
    final hourPaint = Paint()
      ..color = const Color(0xFF6B7A9F) // Lighter muted blue for hands
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    
    final hourHandLength = size.width * 0.22;
    final hourAngle = -90 * (math.pi / 180); // 9 o'clock position
    final hourEnd = Offset(
      center.dx + hourHandLength * 0.7 * math.cos(hourAngle),
      center.dy + hourHandLength * 0.7 * math.sin(hourAngle),
    );
    canvas.drawLine(center, hourEnd, hourPaint);

    // Minute hand (longer, thinner, pointing to 3 o'clock)
    final minutePaint = Paint()
      ..color = const Color(0xFF6B7A9F) // Lighter muted blue for hands
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    
    final minuteHandLength = size.width * 0.32;
    final minuteAngle = 90 * (math.pi / 180); // 3 o'clock position
    final minuteEnd = Offset(
      center.dx + minuteHandLength * 0.75 * math.cos(minuteAngle),
      center.dy + minuteHandLength * 0.75 * math.sin(minuteAngle),
    );
    canvas.drawLine(center, minuteEnd, minutePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
