import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final Map<String, String> chords;
  final String lyrics;
  final List<String> sectionOrder;
  final String creator;
  final String language; // NEW FIELD
  final String type;     // NEW FIELD

  Song({
    required this.id,
    required this.title,
    required this.chords,
    required this.lyrics,
    required this.sectionOrder,
    required this.creator,
    required this.language, // NEW
    required this.type,     // NEW
  });

  factory Song.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? '',
      chords: Map<String, String>.from(data['chords'] ?? {}),
      lyrics: data['lyrics'] ?? '',
      sectionOrder: List<String>.from(
        data['sectionOrder'] ?? (data['chords'] ?? {}).keys,
      ),
      creator: data['creator'] ?? '',
      language: data['language'] ?? 'English', // NEW with default
      type: data['type'] ?? 'Fast Song',       // NEW with default
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'chords': chords,
      'lyrics': lyrics,
      'sectionOrder': sectionOrder,
      'creator': creator,
      'language': language, // NEW
      'type': type,         // NEW
    };
  }
}