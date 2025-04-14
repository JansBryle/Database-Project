import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'request_items.dart';
import 'notifications.dart';
import 'student_profile.dart';

class StudentDashboard extends StatefulWidget {
  final String email;

  const StudentDashboard({super.key, required this.email});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  bool hasOverdue = false;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    final uri = Uri.parse('http://10.0.2.2:5000/student/${widget.email}');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          studentData = data;
          hasOverdue = data['has_overdue'];
          isLoading = false;
        });
      } else {
        print("Failed to fetch student data: ${res.body}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final student = studentData!['student'];
    final transactions = studentData!['transactions'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        backgroundColor: const Color(0xFF006633),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchStudentData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => NotificationsScreen(email: widget.email),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => StudentProfileScreen(email: widget.email),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  student['Name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${student['Course']} • ${student['Year']}'),
                leading: const Icon(Icons.person, color: Color(0xFF006633)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Borrow Transactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  transactions.isEmpty
                      ? const Center(child: Text("No borrow records found."))
                      : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return Card(
                            child: ListTile(
                              title: Text("Items: ${tx['Items']}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Status: ${tx['Status']}"),
                                  Text("Requested: ${tx['RequestDate']}"),
                                  if (tx['DueDate'] != null)
                                    Text("Due: ${tx['DueDate']}"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 10),
            if (hasOverdue)
              const Text(
                "⚠️ You have overdue items. Return them before requesting new ones.",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text(
                  "Request Items",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                onPressed:
                    hasOverdue
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      RequestItemsScreen(email: widget.email),
                            ),
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006633),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
