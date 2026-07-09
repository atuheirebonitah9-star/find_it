import 'package:flutter/material.dart';
import '../matching_logic.dart';
import '../services/report_service.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Report Item Screen - coming soon')),
    );
  }
}
