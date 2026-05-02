import 'package:edify/signup.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class Texted extends StatelessWidget {
  const Texted({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF6366F1),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFF6366F1), const Color(0xFF4338CA)],
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 100),
            // Welcome Header
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.school_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "UniMate",
                    style: TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your ultimate campus companion",
                    style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 16),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom White/Dark Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(35, 50, 35, 50),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50)
                ),
              ),
              child: Column(
                children: <Widget>[
                  // CREATE ACCOUNT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          // ✅ FIXED: Yahan (val) add kiya hai taake 'dynamic Function(bool)' wala error khatam ho (image_ae976b.jpg)
                          builder: (context) => SignupPage(onThemeChanged: (val) {}),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                      ),
                      child: const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LOG IN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          // ✅ FIXED: Yahan bhi (val) add kiya hai (image_ae976b.jpg)
                          builder: (context) => LoginPage(onThemeChanged: (val) {}),
                        ));
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("LOG IN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6366F1))),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "By continuing you agree to our Terms & Conditions",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}