import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'login.dart'; // ✅ Login page import lazmi hai

class ProfilePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const ProfilePage({super.key, required this.onThemeChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  // ☁️ Cloudinary Details
  final String _cloudName = "dbb1ru8me";
  final String _uploadPreset = "abdullah514";

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 🚪 Logout Function
  void _logoutUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout from UniMate?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage(onThemeChanged: widget.onThemeChanged)),
                    (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePic() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        var uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
        var request = http.MultipartRequest("POST", uri);
        request.fields['upload_preset'] = _uploadPreset;
        request.files.add(await http.MultipartFile.fromPath('file', image.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var jsonResponse = jsonDecode(utf8.decode(responseData));
          String secureUrl = jsonResponse['secure_url'];

          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
            'profilePic': secureUrl,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Photo Updated! ✨"), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        debugPrint("Cloudinary Error: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> userData) async {
    TextEditingController nameController = TextEditingController(text: userData['name']);
    TextEditingController uniController = TextEditingController(text: userData['university']);
    TextEditingController semController = TextEditingController(text: userData['semester']);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25, right: 25, top: 25,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Update Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 25),
            _buildTextField(nameController, "Full Name", Icons.person_outline, isDark),
            const SizedBox(height: 15),
            _buildTextField(uniController, "University", Icons.school_outlined, isDark),
            const SizedBox(height: 15),
            _buildTextField(semController, "Semester", Icons.layers_outlined, isDark),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                    'name': nameController.text.trim(),
                    'university': uniController.text.trim(),
                    'semester': semController.text.trim(),
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isDark) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: isDark ? Colors.black.withAlpha(30) : Colors.grey.withAlpha(20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Student Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF6366F1),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
        actions: [
          // 🚪 Top Logout Icon
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logoutUser,
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
                value: isDark,
                activeColor: Colors.amber,
                onChanged: (value) => widget.onThemeChanged(value)
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String? profileUrl = userData['profilePic'];

          return SingleChildScrollView(
            child: FadeTransition(
              opacity: _animationController,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withAlpha(80), blurRadius: 20)],
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            backgroundImage: profileUrl != null && profileUrl.startsWith('http')
                                ? NetworkImage(profileUrl)
                                : null,
                            child: profileUrl == null ? Icon(Icons.person_rounded, size: 70, color: Colors.grey.withAlpha(100)) : null,
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: _updateProfilePic,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                              child: _isUploading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(userData['name'] ?? "Welcome!", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  Text(user!.email ?? "", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),

                  const SizedBox(height: 40),

                  _buildAnimatedInfoTile(Icons.school_rounded, "University", userData['university'] ?? "Not Set", isDark, 1),
                  _buildAnimatedInfoTile(Icons.layers_rounded, "Semester", userData['semester'] ?? "Not Set", isDark, 2),
                  _buildAnimatedInfoTile(Icons.verified_user_rounded, "Status", "Verified Student", isDark, 3),

                  const SizedBox(height: 40),

                  // ✏️ Edit Profile Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withAlpha(60), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => _showEditDialog(userData),
                        child: const Text("EDIT PROFILE INFO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🚪 Bottom Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _logoutUser,
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: const Text("LOGOUT ACCOUNT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedInfoTile(IconData icon, String label, String value, bool isDark, int delayIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 5), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}