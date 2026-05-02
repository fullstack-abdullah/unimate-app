import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Firebase Auth zaroori hai
import 'login.dart';
import 'dashboard.dart'; // ✅ Dashboard import karein

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 3.5 Seconds ka delay taake animation enjoy kar sakein
    Timer(const Duration(milliseconds: 3500), () {
      _checkUserStatus();
    });
  }

  void _checkUserStatus() {
    if (!mounted) return;

    // ✅ Yahan check hoga ke user login hai ya nahi
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Agar login hai to seedha Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(onThemeChanged: widget.onThemeChanged),
        ),
      );
    } else {
      // Agar login nahi hai to Login Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(onThemeChanged: widget.onThemeChanged),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFF6366F1), const Color(0xFF4338CA)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✨ Aapki Lottie Animation
            Lottie.asset(
              'assets/animations/study.json',
              width: 280,
              height: 280,
              fit: BoxFit.contain,
              // Agar path ghalat ho ya file na mile toh ye icon dikhega
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school_rounded, size: 100, color: Colors.white);
              },
            ),
            const SizedBox(height: 30),
            const Text(
              "UniMate",
              style: TextStyle(
                color: Colors.white,
                fontSize: 45,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your Intelligent Campus Companion",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 50),
            // Aik chota sa loading indicator niche
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}