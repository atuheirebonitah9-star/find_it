import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../matching_logic.dart';
import '../services/report_service.dart';
import '../services/image_classification_service.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import 'chat/chat_screen.dart';
import 'possible_matches_screen.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ReportService _reportService = ReportService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();
  final ImageClassificationService _classificationService =
      ImageClassificationService();

  bool isLost = true;
  String? selectedCategory;
  DateTime? selectedDate;
  bool _isListening = false;
  bool _isUploadingImage = false;
  bool _isClassifying = false;

  File? _selectedImage;
  String? _autoCategory;

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String locationText = '';

  final List<String> categories = [
    'Wallet',
    'Phone',
    'ID Card',
    'Keys',
    'Bag',
    'Laptop',
    'Glasses',
    'Other',
  ];

  final Map<String, String> locations = {
    'LLT 1A': 'level 1',
    'LLT 1B': 'level 1',
    'Big Lab 1': 'level 1',
    'Corridor - Level 1': 'level 1',
    'Toilets - Level 1': 'level 1',
    'LLT 2A': 'level 2',
    'LLT 2B': 'level 2',
    'LLT 2C': 'level 2',
    'Big Lab 2': 'level 2',
    'Leaders Office': 'level 2',
    'Corridor - Level 2': 'level 2',
    'Toilets - Level 2': 'level 2',
    'LLT 3A': 'level 3',
    'LLT 3B': 'level 3',
    'Corridor - Level 3': 'level 3',
    'Toilets - Level 3': 'level 3',
    'LLT 4A': 'level 4',
    'LLT 4B': 'level 4',
    'Lab 4': 'level 4',
    'Corridor - Level 4': 'level 4',
    'Toilets - Level 4': 'level 4',
    'LLT 5A': 'level 5',
    'LLT 5B': 'level 5',
    'Corridor - Level 5': 'level 5',
    'Toilets - Level 5': 'level 5',
    'LLT 6A': 'level 6',
    'LLT 6B': 'level 6',
    'Lab 6': 'level 6',
    'Corridor - Level 6': 'level 6',
    'Toilets - Level 6': 'level 6',
    'Canteen': 'general',
  };

  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _speech.stop();
    itemNameController.dispose();
    descriptionController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // ============ METHODS ============
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
            dialogBackgroundColor: AppColors.surface,
          ),
          child: child!,
        );
      },
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

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _isUploadingImage = true;
      _isClassifying = true;
    });

    try {
      final category = await _classificationService.classifyImage(
        pickedFile.path,
      );
      if (mounted && category != null) {
        setState(() {
          _autoCategory = category;
          selectedCategory = category;
          _isClassifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                const SizedBox(width: 8),
                Text(
                  'AI detected: $category',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        setState(() => _isClassifying = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClassifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Classification failed: $e'),
            backgroundColor: AppColors.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _autoCategory = null;
      selectedCategory = null;
    });
  }

  Future<void> _openChatWithMatch(MatchDocument match) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatId = await chatProvider.createChat(
      finderUid: FirebaseAuth.instance.currentUser?.uid ?? '',
      ownerUid: match.report.userId ?? '',
      itemName: match.report.itemName,
    );

    if (mounted) {
      Navigator.push(
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
  }

  // ============ UPDATED: ALWAYS SHOW POSSIBLE MATCHES ============
  Future<void> _handleMatches(List<MatchDocument> matches) async {
    // Clear the form first
    _clearForm();

    if (matches.isEmpty) {
      // No matches found
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLost
                  ? 'Lost report submitted. No matches found yet.'
                  : 'Found report submitted. No matches found yet.',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    // ALWAYS show the Possible Matches screen first
    // This lets users see all potential matches before deciding to chat
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PossibleMatchesScreen(
            matches: matches,
          ),
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate() &&
        selectedCategory != null &&
        selectedDate != null) {
      try {
        final report = Report(
          category: selectedCategory!,
          location: locationText.trim(),
          date: selectedDate!,
          description: descriptionController.text.trim(),
          itemName: itemNameController.text.trim(),
          imageUrl: _selectedImage?.path,
        );

        if (isLost) {
          final matches = await _reportService.submitLostReport(report);
          await _handleMatches(matches);
        } else {
          final matches = await _reportService.submitFoundReport(report);
          await _handleMatches(matches);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit report: $e'),
              backgroundColor: AppColors.errorContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  void _clearForm() {
    setState(() {
      selectedCategory = null;
      selectedDate = null;
      locationText = '';
      itemNameController.clear();
      descriptionController.clear();
      _selectedImage = null;
      _autoCategory = null;
    });
  }

  // ============ UI WIDGETS ============

  Widget _buildLostFoundToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLost = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isLost ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isLost
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      color: isLost ? Colors.black : AppColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lost',
                      style: TextStyle(
                        color: isLost ? Colors.black : AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLost = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isLost ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isLost
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: !isLost ? Colors.black : AppColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Found',
                      style: TextStyle(
                        color: !isLost ? Colors.black : AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Item Photo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                fontSize: 15,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null) ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  if (_isClassifying)
                    Container(
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'AI Analyzing image...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _removeImage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),
                  if (_autoCategory != null && !_isClassifying)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.black,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_autoCategory',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: _isUploadingImage ? null : _showImageSourceSheet,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to add photo',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI will auto-categorize your item',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            fontSize: 15,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
            hint: Row(
              children: [
                Icon(Icons.category, color: AppColors.muted, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Select Category',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            items: categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category,
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() => selectedCategory = value);
            },
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Wallet':
        return Icons.wallet;
      case 'Phone':
        return Icons.phone_android;
      case 'ID Card':
        return Icons.credit_card;
      case 'Keys':
        return Icons.vpn_key;
      case 'Bag':
        return Icons.backpack;
      case 'Laptop':
        return Icons.laptop;
      case 'Glasses':
        return Icons.visibility;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            fontSize: 15,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: selectedDate == null
                          ? AppColors.muted
                          : AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate == null
                          ? 'Select Date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: TextStyle(
                        color: selectedDate == null
                            ? AppColors.muted
                            : AppColors.text,
                        fontWeight: selectedDate == null
                            ? FontWeight.w400
                            : FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            fontSize: 15,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return locations.keys;
            }
            final query = textEditingValue.text.toLowerCase();
            return locations.keys.where((String option) {
              final level = locations[option]!.toLowerCase();
              return option.toLowerCase().contains(query) ||
                  level.contains(query);
            });
          },
          onSelected: (String selection) {
            setState(() => locationText = selection);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (value) => locationText = value,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Type or select a location',
                hintStyle: const TextStyle(color: AppColors.muted),
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.errorContainer,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.errorContainer,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a location'
                  : null,
            );
          },
        ),
      ],
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
            color: AppColors.text,
            fontSize: 15,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.errorContainer,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.errorContainer,
                width: 2,
              ),
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLost ? Icons.search : Icons.check_circle,
                size: 20,
                color: Colors.black,
              ),
              const SizedBox(width: 10),
              Text(
                'Submit ${isLost ? 'Lost' : 'Found'} Report',
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Report an Item',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.surfaceContainerHighest.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isLost ? Icons.search : Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLost
                                  ? 'Report Lost Item'
                                  : 'Report Found Item',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                fontSize: 16,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            Text(
                              isLost
                                  ? 'Help us find your lost item'
                                  : 'Help reunite this item with its owner',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Item Type Toggle
                const Text(
                  'Item Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    fontSize: 15,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 8),
                _buildLostFoundToggle(),
                const SizedBox(height: 24),

                // Image Upload
                _buildImageUploadSection(),
                const SizedBox(height: 20),

                // Category
                _buildCategoryDropdown(),
                const SizedBox(height: 16),

                // Date
                _buildDatePicker(),
                const SizedBox(height: 16),

                // Item Name
                _buildTextField(
                  controller: itemNameController,
                  hint: 'e.g., Black wallet, Blue backpack',
                  label: 'Item Name',
                ),
                const SizedBox(height: 16),

                // Location
                _buildLocationField(),
                const SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: descriptionController,
                  hint: 'Describe the item in detail...',
                  label: 'Description',
                  maxLines: 4,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? AppColors.primary
                          : AppColors.muted,
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
                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}