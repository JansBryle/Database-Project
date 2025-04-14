import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentProfileScreen extends StatefulWidget {
  final String email;

  const StudentProfileScreen({super.key, required this.email});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, dynamic>? student;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
  }

  Future<void> fetchStudentInfo() async {
    final uri = Uri.parse('http://10.0.2.2:5000/student/${widget.email}');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          student = data['student'];
        });
      }
    } catch (e) {
      print("Error fetching student info: $e");
    }
  }

  Future<void> changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() {
        _message = "New passwords do not match.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final uri = Uri.parse('http://10.0.2.2:5000/change_password');
    final body = jsonEncode({
      'email': widget.email,
      'old_password': oldPassword,
      'new_password': newPassword,
    });

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final response = jsonDecode(res.body);
      setState(() {
        _message = response['message'];
      });
    } catch (e) {
      setState(() {
        _message = "Failed to change password. Try again.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: const Color(0xFF006633),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            student == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Name: ${student!['Name']}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text("Course: ${student!['Course']}"),
                      Text("Year: ${student!['Year']}"),
                      const Divider(height: 30),
                      const Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _oldPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Old Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Confirm Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_message != null)
                        Text(
                          _message!,
                          style: TextStyle(
                            color:
                                _message!.contains("success")
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006633),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text("Update Password"),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
