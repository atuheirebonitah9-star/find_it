import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
=======
import '../matching_logic.dart';
import '../services/report_service.dart';
>>>>>>> b3fce2dd28f3c2516edee3d04d2cc87a94fc84f3

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
<<<<<<< HEAD
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();

  String _status = 'lost'; // 'lost' or 'found'
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  static const Color primaryColor = Color(0xFF131B2E);
  static const Color secondaryColor = Color(0xFF006A61);
  static const Color backgroundColor = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color outlineVariant = Color(0xFFC6C6CD);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color errorColor = Color(0xFFBA1A1A);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('item_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await storageRef.putFile(_selectedImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? imageUrl = await _uploadImage();

      await FirebaseFirestore.instance.collection('items').add({
        'itemName': _itemNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'status': _status,
        'imageUrl': imageUrl,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item reported successfully!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to report item: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: outlineVariant),
      prefixIcon: Icon(icon, color: outlineVariant, size: 22),
      filled: true,
      fillColor: surfaceLowest,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      ),
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }
=======
  final ReportService _reportService = ReportService();

  bool isLost = true; // true = Lost, false = Found
  String? selectedCategory;
  DateTime? selectedDate;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<String> categories = [
    'Wallet',
    'Phone',
    'ID Card',
    'Keys',
    'Bag',
    'Other',
  ];
>>>>>>> b3fce2dd28f3c2516edee3d04d2cc87a94fc84f3

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Report Item', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor.withOpacity(0.8),
        elevation: 0,
=======
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A4A),
        title: const Text('Report an Item'),
>>>>>>> b3fce2dd28f3c2516edee3d04d2cc87a94fc84f3
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
<<<<<<< HEAD
                _label('Item Status'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Lost'),
                        value: 'lost',
                        groupValue: _status,
                        onChanged: (value) => setState(() => _status = value!),
                        activeColor: secondaryColor,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Found'),
                        value: 'found',
                        groupValue: _status,
                        onChanged: (value) => setState(() => _status = value!),
                        activeColor: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _label('Item Name'),
                TextFormField(
                  controller: _itemNameController,
                  decoration: _fieldDecoration(hint: 'e.g., Blue Wallet', icon: Icons.label_outline),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _label('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _fieldDecoration(hint: 'Describe the item...', icon: Icons.description_outlined),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _label('Location'),
                TextFormField(
                  controller: _locationController,
                  decoration: _fieldDecoration(hint: 'e.g., Library, Building A', icon: Icons.location_on_outlined),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _label('Contact Info'),
                TextFormField(
                  controller: _contactController,
                  decoration: _fieldDecoration(hint: 'Phone or email', icon: Icons.contact_mail_outlined),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _label('Photo (Optional)'),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: surfaceLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: outlineVariant),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 50, color: outlineVariant),
                                SizedBox(height: 8),
                                Text('Tap to add photo', style: TextStyle(color: outlineVariant)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Text(_errorMessage!, style: const TextStyle(color: errorColor, fontSize: 14)),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
=======
                _buildLostFoundToggle(),
                const SizedBox(height: 24),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: locationController,
                  label: 'Location',
                  hint: 'e.g. Main Library, Cafeteria',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Describe the item in detail',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
>>>>>>> b3fce2dd28f3c2516edee3d04d2cc87a94fc84f3
              ],
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _buildLostFoundToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => isLost = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isLost ? const Color(0xFF1B2A4A) : Colors.transparent,
                border: Border.all(color: const Color(0xFF1B2A4A)),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
              child: Text(
                'Lost',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLost ? Colors.white : const Color(0xFF1B2A4A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => isLost = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !isLost ? const Color(0xFF1B2A4A) : Colors.transparent,
                border: Border.all(color: const Color(0xFF1B2A4A)),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(8),
                ),
              ),
              child: Text(
                'Found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !isLost ? Colors.white : const Color(0xFF1B2A4A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (value) => setState(() => selectedCategory = value),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'This field is required' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() => selectedDate = pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          selectedDate == null
              ? 'Select a date'
              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B2A4A),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _handleSubmit,
      child: Text(
        isLost ? 'Report Lost Item' : 'Report Found Item',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) return;

    final report = Report(
      category: selectedCategory!,
      location: locationController.text,
      date: selectedDate!,
      description: descriptionController.text,
    );

    if (isLost) {
      await _reportService.submitLostReport(report);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lost report submitted!')));
        _clearForm();
      }
    } else {
      await _reportService.submitFoundReport(report);
      final results = await _reportService.checkForMatches(report);
      final hasStrongMatch = results.contains(MatchResult.strong);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasStrongMatch
                  ? 'Strong match found!'
                  : 'Found report submitted. No match yet.',
            ),
          ),
        );
        _clearForm();
      }
    }
  }

  void _clearForm() {
    setState(() {
      selectedCategory = null;
      selectedDate = null;
      locationController.clear();
      descriptionController.clear();
    });
  }
>>>>>>> b3fce2dd28f3c2516edee3d04d2cc87a94fc84f3
}
