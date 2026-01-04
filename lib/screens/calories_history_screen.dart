import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workfit/providers/auth_provider.dart' as app_auth;

import 'package:intl/intl.dart';

class CaloriesHistoryScreen extends StatelessWidget {
  const CaloriesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final userId = authProvider.userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Calories History'),
          backgroundColor: const Color(0xFF7FB77E),
        ),
        body: const Center(child: Text('Please login to view history')),
      );
    }

    // Get date 30 days ago
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Calories History'),
        backgroundColor: const Color(0xFF7FB77E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('workoutHistory')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7FB77E)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final workouts = snapshot.data!.docs;
          int totalCalories = 0;

          for (var doc in workouts) {
            final data = doc.data() as Map<String, dynamic>;
            totalCalories += (data['estimatedCalories'] ?? 0) as int;
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8B87E), Color(0xFFD9A066)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8B87E).withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Total Calories Burned',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalCalories kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Last 30 Days',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Workout List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final doc = workouts[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCalorieCard(data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalorieCard(Map<String, dynamic> data) {
    final calories = data['estimatedCalories'] ?? 0;
    final difficulty = data['difficulty'] ?? 'Unknown';
    final exercises = data['exercisesCompleted'] ?? 0;
    final timeSpent = data['timeSpent'] ?? 0;
    final timestamp = data['date'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Calories
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8B87E), Color(0xFFD9A066)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(difficulty).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        difficulty.toUpperCase(),
                        style: TextStyle(
                          color: _getDifficultyColor(difficulty),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: const TextStyle(
                        color: Color(0xFF9CA89B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSmallStat(Icons.fitness_center, '$exercises ex'),
                    const SizedBox(width: 12),
                    _buildSmallStat(Icons.timer, '${timeSpent ~/ 60}m'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA89B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA89B),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF7FB77E);
      case 'intermediate':
        return const Color(0xFFE8B87E);
      case 'expert':
        return const Color(0xFFCF7E7E);
      default:
        return const Color(0xFF9CA89B);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 80,
            color: const Color(0xFFF2F7F2),
          ),
          const SizedBox(height: 16),
          Text(
            'No workout history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B8269),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start working out to track your calories!',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF9CA89B),
            ),
          ),
        ],
      ),
    );
  }
}