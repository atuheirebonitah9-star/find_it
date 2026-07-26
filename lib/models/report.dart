import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/image_analysis_service.dart';

class Report {
  final String category;
  final String location;
  final DateTime date;
  final String description;
  final String itemName;
  final String? userId;
  final List<double>? embedding;
  final String? imageUrl;
  final ExtractedIdentifiers? extractedIdentifiers;

  Report({
    required this.category,
    required this.location,
    required this.date,
    required this.description,
    required this.itemName,
    this.userId,
    this.embedding,
    this.imageUrl,
    this.extractedIdentifiers,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'location': location,
      'date': date,
      'description': description,
      'itemName': itemName,
      'userId': userId,
      'embedding': embedding,
      'imageUrl': imageUrl,
      if (extractedIdentifiers != null)
        'extractedIdentifiers': extractedIdentifiers!.toMap(),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      itemName: map['itemName'] ?? '',
      userId: map['userId'],
      embedding: map['embedding'] != null
          ? List<double>.from(map['embedding'])
          : null,
      imageUrl: map['imageUrl'],
      extractedIdentifiers: map['extractedIdentifiers'] != null
          ? ExtractedIdentifiers.fromMap(
        Map<String, dynamic>.from(map['extractedIdentifiers']),
      )
          : null,
    );
  }

  Report copyWith({
    String? category,
    String? location,
    DateTime? date,
    String? description,
    String? itemName,
    String? userId,
    List<double>? embedding,
    String? imageUrl,
    ExtractedIdentifiers? extractedIdentifiers,
  }) {
    return Report(
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      description: description ?? this.description,
      itemName: itemName ?? this.itemName,
      userId: userId ?? this.userId,
      embedding: embedding ?? this.embedding,
      imageUrl: imageUrl ?? this.imageUrl,
      extractedIdentifiers: extractedIdentifiers ?? this.extractedIdentifiers,
    );
  }
}