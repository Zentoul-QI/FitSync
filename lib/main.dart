import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:workfit/screens/auth_wrapper.dart';
import 'package:workfit/providers/workout_provider.dart';
import 'package:workfit/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FitSyncApp());
}

class FitSyncApp extends StatelessWidget {
  const FitSyncApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: MaterialApp(
        title: 'FitSync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF66BB6A),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF66BB6A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF66BB6A),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const AuthWrapper(), // ✅ Use AuthWrapper
      ),
    );
  }
}