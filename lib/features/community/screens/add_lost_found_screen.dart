import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddLostFoundScreen extends StatefulWidget {
  const AddLostFoundScreen({super.key});

  @override
  State<AddLostFoundScreen> createState() => _AddLostFoundScreenState();
}

class _AddLostFoundScreenState extends State<AddLostFoundScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _locCtrl    = TextEditingController();
  final _contactCtrl= TextEditingController();

  String _type       = 'Lost';
  bool   _isLoading  = false;
  bool   _isUploading= false;
  String? _imageUrl;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Color get _primaryColor => _type == 'Lost' ? const Color(0xFFEF4444) : const Color(0xFF16A34A);

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Add Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _sourceOption(Icons.photo_library_rounded, 'Gallery', const Color(0xFF16A34A), ImageSource.gallery),
              _sourceOption(Icons.camera_alt_rounded,    'Camera',  const Color(0xFF16A34A), ImageSource.camera),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return;

    setState(() { _isUploading = true; });
    try {
      final bytes = await picked.readAsBytes();
      final ref   = FirebaseStorage.instance.ref().child('lost_found_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      setState(() { _imageUrl = url; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isUploading = false; });
    }
  }

  Widget _sourceOption(IconData icon, String label, Color color, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final payload = <String, dynamic>{
        'type':        _type,
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location':    _locCtrl.text.trim(),
        'contact':     _contactCtrl.text.trim(),
        'timestamp':   FieldValue.serverTimestamp(),
        'postedBy':    user?.uid ?? 'unknown',
        'status':      '',
      };
      if (_imageUrl != null) payload['imageUrl'] = _imageUrl;

      await FirebaseFirestore.instance.collection('community_lost_found').add(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$_type item posted successfully!'),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1, TextInputType keyboard = TextInputType.text, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: _primaryColor) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 2)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Post Item'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type selector
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
                      child: Row(children: [
                        _typeBtn('Lost',  const Color(0xFFEF4444), Icons.help_outline_rounded),
                        _typeBtn('Found', const Color(0xFF3B82F6), Icons.inventory_2_outlined),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Image picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: _imageUrl != null ? 200 : 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _primaryColor.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _isUploading
                            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                CircularProgressIndicator(color: _primaryColor),
                                const SizedBox(height: 8),
                                const Text('Uploading...', style: TextStyle(color: Colors.grey)),
                              ]))
                            : _imageUrl != null
                                ? Stack(fit: StackFit.expand, children: [
                                    Image.network(_imageUrl!, fit: BoxFit.cover),
                                    Positioned(
                                      top: 8, right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _imageUrl = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8, right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(10)),
                                        child: const Row(children: [
                                          Icon(Icons.edit, color: Colors.white, size: 12),
                                          SizedBox(width: 4),
                                          Text('Change', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ]),
                                      ),
                                    ),
                                  ])
                                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                      child: Icon(Icons.add_photo_alternate_outlined, size: 32, color: _primaryColor),
                                    ),
                                    const SizedBox(height: 10),
                                    Text('Add Photo (Optional)', style: TextStyle(fontWeight: FontWeight.w600, color: _primaryColor)),
                                    const SizedBox(height: 2),
                                    const Text('Tap to upload from gallery or camera', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form fields
                    _field(_titleCtrl,   'Item Title (e.g., Black Wallet)', icon: Icons.label_outline),
                    _field(_descCtrl,    'Description / Details', maxLines: 3, icon: Icons.description_outlined),
                    _field(_locCtrl,     'Location',       icon: Icons.location_on_outlined),
                    _field(_contactCtrl, 'Contact Number', icon: Icons.phone_outlined, keyboard: TextInputType.phone),

                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: _primaryColor.withOpacity(0.4),
                      ),
                      onPressed: _submit,
                      child: const Text('Post Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _typeBtn(String label, Color color, IconData icon) {
    final isSelected = _type == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}
