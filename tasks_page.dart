import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final user = FirebaseAuth.instance.currentUser;

  // ✅ Task add karne ka function
  void _addTaskToFirebase(String title, String deadline) async {
    if (title.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('tasks').add({
          'title': title,
          'due': deadline,
          'userId': user?.uid,
          'isDone': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error adding task: $e");
      }
    }
  }

  // ✅ Toggle Task Status
  void _toggleTask(String docId, bool currentStatus) {
    FirebaseFirestore.instance.collection('tasks').doc(docId).update({
      'isDone': !currentStatus,
    });
  }

  void _openPopup() {
    TextEditingController t1 = TextEditingController();
    TextEditingController t2 = TextEditingController();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("New Assignment",
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF6366F1), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: t1,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                    labelText: "Assignment Title",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.assignment_rounded, color: Color(0xFF6366F1))
                )
            ),
            const SizedBox(height: 15),
            TextField(
                controller: t2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                    labelText: "Deadline (e.g. 15 April)",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.event_note_rounded, color: Color(0xFF6366F1))
                )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: () {
              _addTaskToFirebase(t1.text, t2.text);
              Navigator.pop(context);
            },
            child: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
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
        title: const Text("Assignments", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF6366F1),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt_rounded, size: 80, color: Colors.grey.withAlpha(80)),
                  const SizedBox(height: 15),
                  const Text("All caught up! No tasks found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String title = data['title'] ?? 'Untitled';
              String due = data['due'] ?? 'No deadline';
              bool isDone = data['isDone'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  leading: IconButton(
                    icon: Icon(
                      isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isDone ? Colors.green : const Color(0xFF6366F1),
                      size: 28,
                    ),
                    onPressed: () => _toggleTask(docs[index].id, isDone),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey : (isDark ? Colors.white : Colors.black87)
                    ),
                  ),
                  subtitle: Text(
                      "Due: $due",
                      style: TextStyle(color: isDone ? Colors.grey.withAlpha(100) : Colors.grey)
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => docs[index].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPopup,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text("NEW TASK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}