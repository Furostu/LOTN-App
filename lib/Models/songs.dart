import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String chords;
  final String lyrics;

  Song({
    required this.id,
    required this.title,
    required this.chords,
    required this.lyrics,
  });

  factory Song.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? '',
      chords: data['chords'] ?? '',
      lyrics: data['lyrics'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'chords': chords,
      'lyrics': lyrics,
    };
  }
}
