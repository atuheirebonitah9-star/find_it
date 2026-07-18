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

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String locationText = '';

  final List<String> categories = [
    'Wallet',
    'Phone',
    'ID Card',
    'Keys',
    'Bag',
    'Other',
  ];

  final Map<String, String> locations = {
    // Level 1
    'LLT 1A': 'level 1', 'LLT 1B': 'level 1', 'Big Lab 1': 'level 1',
    'Corridor - Level 1': 'level 1', 'Toilets - Level 1': 'level 1',
    // Level 2
    'LLT 2A': 'level 2', 'LLT 2B': 'level 2', 'LLT 2C': 'level 2',
    'Big Lab 2': 'level 2', 'Leaders Office': 'level 2',
    'Corridor - Level 2': 'level 2', 'Toilets - Level 2': 'level 2',
    // Level 3
    'LLT 3A': 'level 3', 'LLT 3B': 'level 3',
    'Corridor - Level 3': 'level 3', 'Toilets - Level 3': 'level 3',
    // Level 4
    'LLT 4A': 'level 4', 'LLT 4B': 'level 4', 'Lab 4': 'level 4',
    'Corridor - Level 4': 'level 4', 'Toilets - Level 4': 'level 4',
    // Level 5
    'LLT 5A': 'level 5', 'LLT 5B': 'level 5',
    'Corridor - Level 5': 'level 5', 'Toilets - Level 5': 'level 5',
    // Level 6
    'LLT 6A': 'level 6', 'LLT 6B': 'level 6', 'Lab 6': 'level 6',
    'Corridor - Level 6': 'level 6', 'Toilets - Level 6': 'level 6',
    // General
    'Canteen': 'general',
  };

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

  Future<void> _handleMatches(List<MatchDocument> matches) async {
    final strongMatch = matches
        .where((m) => m.result == MatchResult.strong)
        .toList();
    final weakMatch = matches
        .where((m) => m.result == MatchResult.weak)
        .toList();

    if (strongMatch.isNotEmpty && mounted) {
      await _openChatWithMatch(strongMatch.first);
      _clearForm();
    } else if (weakMatch.isNotEmpty && mounted) {
      final match = weakMatch.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A possible match was found!'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              _openChatWithMatch(match);
            },
          ),
          duration: const Duration(seconds: 8),
        ),
      );
      _clearForm();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLost
                ? 'Lost report submitted. No match yet.'
                : 'Found report submitted. No match yet.',
          ),
        ),
      );
      _clearForm();
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
      locationText = '';
      itemNameController.clear();
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

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B2A4A),
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
              decoration: InputDecoration(
                hintText: 'Type or select a location',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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

                _buildDatePicker(),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: itemNameController,
                  hint: 'e.g., Black wallet, Blue backpack',
                  label: 'Item Name',
                ),
                const SizedBox(height: 16),

                _buildLocationField(),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: descriptionController,
                  hint: 'Describe the item...',
                  label: 'Description',
                  maxLines: 4,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? Colors.red
                          : const Color(0xFF1B2A4A),
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
