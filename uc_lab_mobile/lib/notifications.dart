import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationsScreen extends StatefulWidget {
  final String email;

  const NotificationsScreen({super.key, required this.email});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final uri = Uri.parse(
      'http://10.0.2.2:5000/student_notifications/${widget.email}',
    );
    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          notifications = data['notifications'];
          isLoading = false;
        });
      } else {
        print("Error fetching notifications: ${res.body}");
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final uri = Uri.parse(
      'http://10.0.2.2:5000/mark_student_notification/$notificationId',
    );
    try {
      final res = await http.post(uri);
      if (res.statusCode == 200) {
        fetchNotifications(); // Refresh
      }
    } catch (e) {
      print("Mark as read error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF006633),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? const Center(child: Text("No notifications."))
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isRead = notif['IsRead'] == 1;
                  return ListTile(
                    title: Text(
                      notif['Message'],
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notif['CreatedAt']),
                    trailing:
                        isRead
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.mark_email_read),
                              onPressed:
                                  () => markAsRead(notif['NotificationID']),
                            ),
                  );
                },
              ),
    );
  }
}
