import 'package:cloud_firestore/cloud_firestore.dart';

/// Which language(s) to show
enum SongLanguageFilter {
  all,
  tagalog,
  english,
}

/// Which song type(s) to show
enum SongTypeFilter {
  all,
  fast,
  slow,
}

class Song {
  final String id;
  final String title;
  final Map<String, String> chords;
  final Map<String, String> lyrics; // Changed from String to Map<String, String>
  final List<String> sectionOrder;
  final String creator;
  final String language;
  final String type;

  Song({
    required this.id,
    required this.title,
    required this.chords,
    required this.lyrics,
    required this.sectionOrder,
    required this.creator,
    required this.language,
    required this.type,
  });

  /// Create a Song from a Firestore document.
  factory Song.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Normalize language and type to lowercase, or empty if missing
    final rawLang = (data['language'] as String?)
        ?.trim()
        .toLowerCase() ??
        '';
    final rawType = (data['type'] as String?)
        ?.trim()
        .toLowerCase() ??
        '';

    // Handle lyrics - check if it's a Map or String for backward compatibility
    Map<String, String> lyricsMap = {};
    if (data['lyrics'] != null) {
      if (data['lyrics'] is Map) {
        lyricsMap = Map<String, String>.from(data['lyrics']);
      } else if (data['lyrics'] is String) {
        // For backward compatibility with existing songs that have lyrics as String
        lyricsMap = {'main': data['lyrics']};
      }
    }

    return Song(
      id: doc.id,
      title: data['title'] ?? '',
      chords: Map<String, String>.from(data['chords'] ?? {}),
      lyrics: lyricsMap,
      sectionOrder: List<String>.from(
        data['sectionOrder'] ??
            (data['chords'] as Map<String, dynamic>?)?.keys.toList() ??
            [],
      ),
      creator: data['creator'] ?? '',
      language: rawLang,
      type: rawType,
    );
  }

  /// Prepare data for writing back to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'chords': chords,
      'lyrics': lyrics, // Now saves as Map<String, String>
      'sectionOrder': sectionOrder,
      'creator': creator,
      'language': language,
      'type': type,
    };
  }
}