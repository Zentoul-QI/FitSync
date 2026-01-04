import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'workout_list_screen.dart';

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2), // Very light green background
      appBar: AppBar(
        title: const Text(
          'Choose Your Level',
          style: TextStyle(
            color: Color(0xFF2D4A2C), // Dark green title
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8FC88E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D4A2C)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7FB77E).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.self_improvement,
                          size: 48,
                          color: Color(0xFF7FB77E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Your Fitness Level',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D4A2C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose the difficulty that matches your current fitness level',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B8269),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _DifficultyCard(
                  title: 'Beginner',
                  description: 'Perfect for starting your fitness journey',
                  reps: '10-15 reps per exercise',
                  icon: Icons.wb_sunny,
                  color: const Color(0xFF7FB77E),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8FC88E), Color(0xFF7FB77E)],
                  ),
                  onTap: () => _navigateToWorkout(context, 'beginner'),
                ),
                const SizedBox(height: 16),
                _DifficultyCard(
                  title: 'Intermediate',
                  description: 'Ready to take it to the next level',
                  reps: '15-20 reps per exercise',
                  icon: Icons.trending_up,
                  color: const Color(0xFFE8B87E),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0C490), Color(0xFFE8B87E)],
                  ),
                  onTap: () => _navigateToWorkout(context, 'intermediate'),
                ),
                const SizedBox(height: 16),
                _DifficultyCard(
                  title: 'Expert',
                  description: 'Push your limits to the maximum',
                  reps: '20-30 reps per exercise',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFCF7E7E),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDB9090), Color(0xFFCF7E7E)],
                  ),
                  onTap: () => _navigateToWorkout(context, 'expert'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWorkout(BuildContext context, String difficulty) {
    Provider.of<WorkoutProvider>(context, listen: false).setDifficulty(difficulty);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WorkoutListScreen()),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String title;
  final String description;
  final String reps;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.title,
    required this.description,
    required this.reps,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B8269),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reps,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}