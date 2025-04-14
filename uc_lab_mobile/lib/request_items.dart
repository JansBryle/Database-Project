import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RequestItemsScreen extends StatefulWidget {
  final String email;

  const RequestItemsScreen({super.key, required this.email});

  @override
  State<RequestItemsScreen> createState() => _RequestItemsScreenState();
}

class _RequestItemsScreenState extends State<RequestItemsScreen> {
  List<dynamic> materials = [];
  Map<int, int> selectedQuantities = {};
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    final uri = Uri.parse('http://10.0.2.2:5000/materials_available');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        setState(() {
          materials = jsonDecode(res.body);
        });
      }
    } catch (e) {
      print("Failed to load materials: $e");
    }
  }

  Future<void> submitRequest() async {
    setState(() => isSubmitting = true);

    final itemsToBorrow =
        selectedQuantities.entries
            .where((entry) => entry.value > 0)
            .map((entry) => {'material_id': entry.key, 'quantity': entry.value})
            .toList();

    if (itemsToBorrow.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one item.")),
      );
      setState(() => isSubmitting = false);
      return;
    }

    final uri = Uri.parse('http://10.0.2.2:5000/borrow_request');
    final body = jsonEncode({'email': widget.email, 'items': itemsToBorrow});

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
        Navigator.pop(context); // Go back to dashboard
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
      }
    } catch (e) {
      print("Submit error: $e");
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Items"),
        backgroundColor: const Color(0xFF006633),
      ),
      body:
          materials.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: materials.length,
                itemBuilder: (context, index) {
                  final material = materials[index];
                  final materialId = material['MaterialID'];
                  return ListTile(
                    title: Text(material['Name']),
                    subtitle: Text("Available: ${material['StockQuantity']}"),
                    trailing: SizedBox(
                      width: 120, // fixed overflow
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                selectedQuantities[materialId] =
                                    (selectedQuantities[materialId] ?? 0) - 1;
                                if (selectedQuantities[materialId]! < 0) {
                                  selectedQuantities[materialId] = 0;
                                }
                              });
                            },
                          ),
                          Text('${selectedQuantities[materialId] ?? 0}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                selectedQuantities[materialId] =
                                    (selectedQuantities[materialId] ?? 0) + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006633),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Borrow Request"),
        ),
      ),
    );
  }
}
