import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddLostFoundScreen extends StatefulWidget {
  const AddLostFoundScreen({super.key});

  @override
  State<AddLostFoundScreen> createState() => _AddLostFoundScreenState();
}

class _AddLostFoundScreenState extends State<AddLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  
  String _type = 'Lost'; // Default to Lost
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('community_lost_found').add({
        'type': _type,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'postedBy': user?.uid ?? 'unknown',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item posted successfully!'), 
            backgroundColor: _type == 'Lost' ? Colors.red : Colors.blue,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error posting item: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = _type == 'Lost' ? Colors.red : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Item"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toggle Buttons for Lost / Found
                    Center(
                      child: ToggleButtons(
                        isSelected: [_type == 'Lost', _type == 'Found'],
                        onPressed: (index) {
                          setState(() {
                            _type = index == 0 ? 'Lost' : 'Found';
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: primaryColor,
                        color: Colors.grey[700],
                        constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                        children: const [
                          Text("Lost", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Found", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(_titleController, "Item Title (e.g., Black Wallet)"),
                    _buildTextField(_descriptionController, "Description / Details", maxLines: 3),
                    _buildTextField(_locationController, "Location"),
                    _buildTextField(_contactController, "Contact Number", keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitItem,
                      child: const Text("Post Item", style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
