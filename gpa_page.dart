import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';

class GpaPage extends StatefulWidget {
  const GpaPage({super.key});

  @override
  State<GpaPage> createState() => _GpaPageState();
}

class _GpaPageState extends State<GpaPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _creditController = TextEditingController();
  String _selectedGrade = 'A';
  String _selectedSemester = '1st';

  final Map<String, double> _gradePoints = {
    'A': 4.0, 'A-': 3.7, 'B+': 3.3, 'B': 3.0, 'B-': 2.7,
    'C+': 2.3, 'C': 2.0, 'C-': 1.7, 'D+': 1.3, 'D': 1.0, 'F': 0.0
  };

  final List<String> _semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];

  Color _getGradeColor(String grade) {
    // FIX: Colors.emerald ko Colors.green se badal diya
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.indigoAccent;
    if (grade.startsWith('C')) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _addSubject() async {
    if (_nameController.text.isEmpty || _creditController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('gpa_records').add({
        'userId': user?.uid,
        'subjectName': _nameController.text.trim(),
        'semester': _selectedSemester,
        'credits': double.parse(_creditController.text),
        'grade': _selectedGrade,
        'points': _gradePoints[_selectedGrade],
        'timestamp': FieldValue.serverTimestamp(),
      });
      _nameController.clear();
      _creditController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  double _calculateGPA(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0.0;
    double totalPoints = 0;
    double totalCredits = 0;
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      double credits = (data['credits'] ?? 0).toDouble();
      double points = (data['points'] ?? 0).toDouble();
      totalPoints += (points * credits);
      totalCredits += credits;
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // FIX: Variable ka naam gpaStream rakha (underscore hata diya warning khatam karne ke liye)
    final Stream<QuerySnapshot> gpaStream = FirebaseFirestore.instance
        .collection('gpa_records')
        .where('userId', isEqualTo: user?.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: gpaStream,
              builder: (context, snapshot) {
                double cgpa = 0.0;
                if (snapshot.hasData) {
                  cgpa = _calculateGPA(snapshot.data!.docs);
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      CircularPercentIndicator(
                        radius: 75.0,
                        lineWidth: 10.0,
                        percent: cgpa / 4.0,
                        animation: true,
                        circularStrokeCap: CircularStrokeCap.round,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cgpa.toStringAsFixed(2),
                                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                            const Text("CGPA", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white.withAlpha(40),
                      ),
                    ],
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isDark ? Colors.blue.withAlpha(30) : Colors.grey.withAlpha(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Add New Subject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedSemester,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                            underline: const SizedBox(),
                            items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
                            onChanged: (v) => setState(() => _selectedSemester = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(_nameController, "Subject Name", Icons.auto_stories_outlined, isDark),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(_creditController, "Credits", Icons.star_border_rounded, isDark, isNumber: true)),
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withAlpha(40) : Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedGrade,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            underline: const SizedBox(),
                            items: _gradePoints.keys.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (v) => setState(() => _selectedGrade = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 5,
                          shadowColor: const Color(0xFF6366F1).withAlpha(100),
                        ),
                        onPressed: _addSubject,
                        child: const Text("Calculate & Add Record", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Align(alignment: Alignment.centerLeft, child: Text("Grade History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: gpaStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text("No records added yet.", style: TextStyle(color: Colors.grey)),
                  );
                }
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String grade = data['grade'] ?? 'A';
                    String sem = data['semester'] ?? '1st';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getGradeColor(grade).withAlpha(40)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getGradeColor(grade).withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Text(grade, style: TextStyle(color: _getGradeColor(grade), fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        title: Text(data['subjectName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Semester $sem  •  ${data['credits']} Credits", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                          onPressed: () => FirebaseFirestore.instance.collection('gpa_records').doc(docs[index].id).delete(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, bool isDark, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        filled: true,
        fillColor: isDark ? Colors.black.withAlpha(40) : Colors.grey.withAlpha(20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}