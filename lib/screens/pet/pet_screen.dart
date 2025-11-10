import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import 'dart:math' as math;

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8E5F5), // Light purple/lavender
              Color(0xFFEEF2F6), // Light gray
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<PetProvider>(
            builder: (context, petProvider, child) {
              if (petProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B9FDE),
                  ),
                );
              }

              final consecutiveDays = petProvider.consecutiveDays;
              final treeEmoji = petProvider.treeEmoji;
              final backgroundTreeCount = petProvider.backgroundTreeCount;

              return Stack(
                children: [
                  // Background trees
                  ..._buildBackgroundTrees(backgroundTreeCount),
                  
                  // Main content
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      // Explanation text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: const [
                            Text(
                              'Your focus tree grows as you study each day.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Keep your streak to help it flourish.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Main tree with animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Text(
                            treeEmoji,
                            style: const TextStyle(
                              fontSize: 140,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Day counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Day ${consecutiveDays + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B9FDE),
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Growth stage info
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              petProvider.pet?.stageName ?? 'Seed',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getStageMessage(petProvider.growthStage),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (backgroundTreeCount > 0) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '🌲',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$backgroundTreeCount Background ${backgroundTreeCount == 1 ? "Tree" : "Trees"}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8B9FDE),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundTrees(int count) {
    if (count == 0) return [];

    final List<Widget> trees = [];
    final random = math.Random(42); // Fixed seed for consistent positions

    for (int i = 0; i < count; i++) {
      final left = random.nextDouble() * 0.8; // 0-80% from left
      final top = random.nextDouble() * 0.6; // 0-60% from top
      final size = 40.0 + random.nextDouble() * 30; // 40-70 size

      trees.add(
        Positioned(
          left: MediaQuery.of(context).size.width * left,
          top: MediaQuery.of(context).size.height * top,
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 500 + (i * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value * 0.15, // 15% opacity
                child: Text(
                  '🌲',
                  style: TextStyle(
                    fontSize: size,
                    height: 1,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return trees;
  }

  String _getStageMessage(int stage) {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final days = petProvider.consecutiveDays;
    
    // Special milestone messages
    if (days >= 365) return '🎉 ONE YEAR STREAK! You\'re a legend!';
    if (days >= 180) return '💎 Half a year! Incredible dedication!';
    if (days >= 100) return '⭐ 100 days! You\'ve joined the Century Club!';
    if (days >= 50) return '✨ 50 days! Your consistency is inspiring!';
    if (days >= 30) return '🌟 30 days! A full month of growth!';
    if (days >= 21) return '🔥 3 weeks! Habits are forming!';
    
    // Regular growth stage messages
    switch (stage) {
      case 0:
        return 'Complete a study session to plant your seed!';
      case 1:
        return 'Your seed is sprouting! Keep going!';
      case 2:
        return 'Growing stronger day by day!';
      case 3:
        return 'Your plant is taking shape beautifully!';
      case 4:
        return 'A small tree is emerging!';
      case 5:
        return 'Your tree is maturing nicely!';
      case 6:
        return 'Fully grown! Keep the streak alive!';
      default:
        return 'Start your journey today!';
    }
  }
}
