import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/percent_indicator.dart';
// Note: intl import unused warnings fix karne ke liye agar use nahi ho raha to hata dein
import 'tasks_page.dart';
import 'attendance_page.dart';
import 'gpa_page.dart';
import 'profile_page.dart';
import 'resources_page.dart';
import 'ai_assistant_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const DashboardPage({super.key, required this.onThemeChanged});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final DatabaseReference _noticeRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://edify-8bca0-default-rtdb.firebaseio.com/",
  ).ref().child("notices");

  void _showPostNoticeDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text("Post New Notice", style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: _controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "What's happening?",
            filled: true,
            fillColor: Colors.grey.withAlpha(25), // withOpacity ki jagah withAlpha behtar hai
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                await _noticeRef.set({
                  "message": _controller.text,
                  "time": DateTime.now().millisecondsSinceEpoch,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Post", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("UniMate", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
            Text("Your Academic Ally", style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF6366F1),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => widget.onThemeChanged(!isDark),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(onThemeChanged: widget.onThemeChanged))),
            icon: const Icon(Icons.account_circle_outlined, size: 28),
          ),
        ],
      ),
      body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeContent(),
            const TasksPage(),
            const AttendancePage(),
            const GpaPage(),
          ]
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF6366F1),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: "Tasks"),
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: "Attendance"),
              BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: "GPA"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final user = FirebaseAuth.instance.currentUser;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF6366F1).withAlpha(50),
                child: const Text("🎓", style: TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome back,", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text("${user?.displayName ?? 'Scholar'}!",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              const Spacer(),
              FloatingActionButton.small(
                onPressed: _showPostNoticeDialog,
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(Icons.add, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatIndicator("Attendance", 0.75, "75%", Colors.green), // Fix: emerald to green
                Container(height: 50, width: 1, color: Colors.grey.withAlpha(50)),
                _buildStatIndicator("Current GPA", 0.85, "3.4", Colors.indigoAccent),
              ],
            ),
          ),
          const SizedBox(height: 25),
          StreamBuilder(
            stream: _noticeRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withAlpha(80), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text("Notice Board", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(data['message'] ?? "", style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 30),
          const Text("Quick Shortcuts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.3,
            children: [
              _buildModernAction("AI Helper", Icons.psychology_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantPage()))),
              _buildModernAction("GPA Calc", Icons.calculate_rounded, Colors.blue, () => setState(() => _selectedIndex = 3)),
              _buildModernAction("Attendance", Icons.fact_check_rounded, Colors.orange, () => setState(() => _selectedIndex = 2)),
              _buildModernAction("Resources", Icons.folder_copy_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourcesPage()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(String title, double percent, String val, Color color) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 35.0,
          lineWidth: 8.0,
          percent: percent,
          center: Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          progressColor: color,
          backgroundColor: color.withAlpha(25),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
      ],
    );
  }

  Widget _buildModernAction(String title, IconData icon, Color color, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}