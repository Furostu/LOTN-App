import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final Map<String, String> chords;
  final String lyrics;
  final List<String> sectionOrder;
  final String creator; // ✅ Added creator field

  Song({
    required this.id,
    required this.title,
    required this.chords,
    required this.lyrics,
    required this.sectionOrder,
    required this.creator, // ✅ Include in constructor
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
      creator: data['creator'] ?? '', // ✅ Handle creator from Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'chords': chords,
      'lyrics': lyrics,
      'sectionOrder': sectionOrder,
      'creator': creator, // ✅ Save creator to Firestore
    };
  }
}
