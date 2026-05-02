import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final user = FirebaseAuth.instance.currentUser;

  void _deleteSubject(String docId, String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Subject?", style: TextStyle(color: Colors.white)),
        content: Text("Kya aap waqayi '$subjectName' ko delete karna chahte hain?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('subjects').doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    final creditController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Subject", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Subject Name",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(30))),
              ),
            ),
            TextField(
              controller: creditController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Credit Hours",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(30))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('subjects').add({
                  'name': nameController.text.trim(),
                  'creditHours': creditController.text.trim(),
                  'present': 0, 'absent': 0, 'total': 0,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
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
        title: const Text("Attendance Manager", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF6366F1),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: _showAddSubjectDialog, icon: const Icon(Icons.add_circle_outline, color: Colors.white)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text("No subjects added yet.", style: TextStyle(color: Colors.grey.shade500)));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              int present = data['present'] ?? 0;
              int total = data['total'] ?? 0;
              double percentage = total == 0 ? 0 : (present / total);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectDetailPage(docId: docs[index].id, subjectName: data['name']))),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.withAlpha(40),
                        color: percentage < 0.75 ? Colors.orange : Colors.green,
                        strokeWidth: 5,
                      ),
                      Text("${(percentage * 100).toInt()}%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                  title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("P: $present | T: $total (CH: ${data['creditHours']})", style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteSubject(docs[index].id, data['name'])),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SubjectDetailPage extends StatefulWidget {
  final String docId;
  final String subjectName;
  const SubjectDetailPage({super.key, required this.docId, required this.subjectName});
  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  bool _isProcessing = false;

  Future<void> _markAttendance(bool isPresent) async {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final String todayId = "${widget.docId}_${now.year}_${now.month}_${now.day}";
    setState(() => _isProcessing = true);

    try {
      final logRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('attendance_logs').doc(todayId);
      final logDoc = await logRef.get();

      if (logDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance already marked for today! ❌"), backgroundColor: Colors.redAccent));
      } else {
        var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('subjects').doc(widget.docId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(docRef, {isPresent ? 'present' : 'absent': FieldValue.increment(1), 'total': FieldValue.increment(1)});
          transaction.set(logRef, {'date': DateTime.now(), 'status': isPresent ? 'Present' : 'Absent'});
        });
        if (!mounted) return;
        Navigator.pop(context);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(widget.subjectName), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: _isProcessing ? const CircularProgressIndicator() : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_rounded, size: 80, color: const Color(0xFF6366F1).withAlpha(150)),
            const SizedBox(height: 20),
            const Text("Mark Attendance", style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text(widget.subjectName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton("PRESENT", Colors.green, () => _markAttendance(true)),
                _actionButton("ABSENT", Colors.redAccent, () => _markAttendance(false)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}