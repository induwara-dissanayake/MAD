import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _contactController = TextEditingController();
  final _descController = TextEditingController();

  String _jobType = 'Full-time';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _contactController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('community_jobs').add({
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'salary': _salaryController.text.trim(),
        'contact': _contactController.text.trim(),
        'description': _descController.text.trim(),
        'jobType': _jobType,
        'date': DateFormat('MMM dd').format(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
        'postedBy': user?.uid ?? 'unknown',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Job posted successfully!'),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    IconData? icon,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: _green, size: 20) : null,
          labelStyle: const TextStyle(color: Color(0xFF475569)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: required
            ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter $label' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Post a Job',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_greenDark, Color(0xFF43A047)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.work_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Job Listing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Fill in the details below',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Job Type Selector
                    const Text(
                      'Job Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _typeBtn(
                            'Full-time',
                            Icons.badge_rounded,
                            const Color(0xFF1565C0),
                          ),
                          _typeBtn(
                            'Part-time',
                            Icons.access_time_rounded,
                            const Color(0xFF6A1B9A),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section label
                    _sectionLabel('Job Details'),
                    const SizedBox(height: 12),

                    _buildField(
                      _titleController,
                      'Job Title',
                      'e.g. Delivery Driver',
                      icon: Icons.work_outline_rounded,
                    ),
                    _buildField(
                      _companyController,
                      'Company / Employer',
                      'e.g. Saman Stores',
                      icon: Icons.business_rounded,
                    ),
                    _buildField(
                      _descController,
                      'Job Description',
                      'Describe the role & requirements...',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      required: false,
                    ),

                    _sectionLabel('Location & Pay'),
                    const SizedBox(height: 12),

                    _buildField(
                      _locationController,
                      'Location',
                      'e.g. Kaduwela Town',
                      icon: Icons.location_on_outlined,
                    ),
                    _buildField(
                      _salaryController,
                      'Salary / Pay',
                      'e.g. LKR 25,000 / month',
                      icon: Icons.payments_outlined,
                      required: false,
                    ),

                    _sectionLabel('Contact'),
                    const SizedBox(height: 12),

                    _buildField(
                      _contactController,
                      'Contact Number',
                      'e.g. 0771234567',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                    ),

                    const SizedBox(height: 28),

                    // Submit button
                    GestureDetector(
                      onTap: _submitJob,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_greenDark, Color(0xFF43A047)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _green.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.publish_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Publish Job',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _typeBtn(String label, IconData icon, Color color) {
    final isSelected = _jobType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jobType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
