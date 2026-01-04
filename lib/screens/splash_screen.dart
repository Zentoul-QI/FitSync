import 'package:flutter/material.dart';
import 'dart:async';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scaleController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const AuthScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F3D2E), // deep green
              Color(0xFF1B5E4A),
              Color(0xFF2E7D5B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                const Spacer(flex: 2),

                /// LOGO
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E4A),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF6EE7B7),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 70,
                        color: Color(0xFF6EE7B7),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                /// APP NAME
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'FitSync',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6FFFA),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// TAGLINE
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF134E3A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Your AI Fitness Companion',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB9FBC0),
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                /// WELCOME CARD
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 36),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF134E3A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF6EE7B7),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.waving_hand,
                            color: Color(0xFF6EE7B7), size: 32),
                        SizedBox(height: 12),
                        Text(
                          'Welcome to FitSync',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE6FFFA),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Transform your body with AI-powered\nworkout tracking and real-time feedback',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB9FBC0),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                /// LOADING
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF6EE7B7)),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Loading your fitness experience...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB9FBC0),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
