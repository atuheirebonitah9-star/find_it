import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../matching_logic.dart';
import '../services/report_service.dart';
import '../providers/chat_provider.dart';
import 'chat/chat_screen.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReportService _reportService = ReportService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool isLost = true; // true = Lost, false = Found
  String? selectedCategory;
  DateTime? selectedDate;
  bool _isListening = false;
  XFile? _pickedImage;  

  final TextEditingController itemNameController = TextEditingController();
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
Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Could not access camera. Check app permissions.'
                : 'Could not access photos. Check app permissions.',
          ),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _initSpeech() async {
    final bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (val) {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
    );

    if (available && mounted) {
      setState(() {});
    }
  }

  Future<void> _startListening() async {
    if (!_speech.isAvailable) {
      await _initSpeech();
    }

    if (_speech.isAvailable && !_isListening && mounted) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult && mounted) {
            setState(() {
              descriptionController.text += ' ${result.recognizedWords}';
              descriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: descriptionController.text.length),
              );
            });
          }
        },
      );
    }
  }

  Future<void> _stopListening() async {
    if (_speech.isListening && mounted) {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

Future<void> _submitReport() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo of the item.'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() &&
        selectedCategory != null &&
        selectedDate != null) {  
      try {
        final report = Report(
          category: selectedCategory!,
          location: locationController.text.trim(),
          date: selectedDate!,
          description: descriptionController.text.trim(),
          itemName: itemNameController.text.trim(),
        );

        if (isLost) {
          await _reportService.submitLostReport(report);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lost report submitted!')),
            );
            _clearForm();
          }
        } else {
          await _reportService.submitFoundReport(report);
          final matches = await _reportService.checkForMatches(report);

          if (matches.isNotEmpty && mounted) {
            // Get first strong match
            final match = matches.first;
            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            final chatId = await chatProvider.createChat(
              finderUid: FirebaseAuth.instance.currentUser?.uid ?? '',
              ownerUid: match.report.userId ?? '',
              itemName: match.report.itemName,
            );

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chatId,
                    otherUserUid: match.report.userId ?? '',
                    itemName: match.report.itemName,
                  ),
                ),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Found report submitted. No match yet.')),
            );
            _clearForm();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit report: $e')),
          );
        }
      }
    }
  }

  void _clearForm() {
    setState(() {
      selectedCategory = null;
      selectedDate = null;
      itemNameController.clear();
      locationController.clear();
      descriptionController.clear();
    });
  }

  Widget _buildLostFoundToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLost = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isLost ? const Color(0xFF1B2A4A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lost',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLost ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLost = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isLost ? const Color(0xFF1B2A4A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !isLost ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCategory,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
        hint: const Text('Select Category'),
        items: categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() => selectedCategory = value);
        },
        validator: (value) => value == null ? 'Please select a category' : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate == null
                  ? 'Select Date'
                  : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
              style: TextStyle(
                color: selectedDate == null ? Colors.grey[600] : Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today, color: Color(0xFF1B2A4A)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B2A4A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1B2A4A),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    itemNameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A4A),
        title: const Text('Report an Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Item Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2A4A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLostFoundToggle(),
                const SizedBox(height: 24),

                _buildCategoryDropdown(),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: itemNameController,
                  hint: 'e.g., Black Leather Wallet',
                  label: 'Item Name',
                ),
                const SizedBox(height: 16),

                _buildDatePicker(),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: locationController,
                  hint: 'e.g., Library, Building A',
                  label: 'Location',
                ),
                const SizedBox(height: 16),
_buildTextField(
                  controller: descriptionController,
                  hint: 'Describe the item...',
                  label: 'Description',
                  maxLines: 4,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : const Color(0xFF1B2A4A),
                    ),
                    onPressed: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera_outlined,
                      color: Color(0xFF1B2A4A)),
                  label: const Text(
                    'Upload a photo',
                    style: TextStyle(color: Color(0xFF1B2A4A)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1B2A4A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (_pickedImage != null) ...[
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedImage!.path),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                            onPressed: () =>
                                setState(() => _pickedImage = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2A4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
