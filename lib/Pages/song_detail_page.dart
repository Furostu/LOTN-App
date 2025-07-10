import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/songs.dart';
import '../Services/auth_service.dart';
import '../transition.dart';
import 'edit_song_page.dart';

// Define color palette
class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color darkGray1 = Color(0xFF1F1F1F);
  static const Color darkGray2 = Color(0xFF242424);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray1 = Color(0xFFF2F2F2);
  static const Color lightGray2 = Color(0xFFE2E2E2);
}

class SongDetailPage extends StatefulWidget {
  final Song song;

  const SongDetailPage({super.key, required this.song});

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  bool _showChords = true;
  double _fontScale = 1.0;
  int _transposeSteps = 0;
  bool _isBookmarked = false;

  // Chord mapping for transposition
  static const List<String> _chromaticScale = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const Map<String, String> _enharmonicEquivalents = {
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#'
  };

  // Transpose a single chord
  String _transposeChord(String chord) {
    if (_transposeSteps == 0) return chord;

    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      String mainChord = _transposeSingleChord(parts[0]);
      String bassChord = _transposeSingleChord(parts[1]);
      return '$mainChord/$bassChord';
    }
    return _transposeSingleChord(chord);
  }

  String _transposeSingleChord(String chord) {
    if (_transposeSteps == 0 || chord.isEmpty) return chord;

    String rootNote = '';
    String suffix = '';

    // Extract root note and suffix
    if (chord.length >= 2 && (chord[1] == '#' || chord[1] == 'b')) {
      rootNote = chord.substring(0, 2);
      suffix = chord.substring(2);
    } else {
      rootNote = chord.substring(0, 1);
      suffix = chord.substring(1);
    }

    // Debug print - remove after fixing
    print('Original chord: "$chord", Root: "$rootNote", Suffix: "$suffix"');

    // Convert flat notes to sharp equivalents
    if (_enharmonicEquivalents.containsKey(rootNote)) {
      rootNote = _enharmonicEquivalents[rootNote]!;
    }

    // Find the index in chromatic scale
    int currentIndex = _chromaticScale.indexOf(rootNote);
    print('Current index for "$rootNote": $currentIndex');

    if (currentIndex == -1) {
      print('Root note "$rootNote" not found in chromatic scale');
      return chord; // Return original if not found
    }

    // Calculate new index with proper modulo handling
    int newIndex = (currentIndex + _transposeSteps) % 12;
    if (newIndex < 0) newIndex += 12;

    String result = _chromaticScale[newIndex] + suffix;
    print('Transposed result: "$result"');

    return result;
  }

  void _updateTranspose(int change) {
    setState(() {
      _transposeSteps += change;
    });
    _saveTransposeSettings();
  }

  Map<String, String> get _transposedChords {
    if (_transposeSteps == 0) return widget.song.chords;
    Map<String, String> transposed = {};
    widget.song.chords.forEach((key, value) {
      transposed[key] = _transposeChordProgression(value);
    });
    return transposed;
  }

  String _transposeChordProgression(String chordProgression) {
    if (_transposeSteps == 0) return chordProgression;

    // Debug: Show what we're trying to transpose
    print('Transposing chord progression: "$chordProgression"');

    // Updated regex to better match chord patterns in your format
    String result = chordProgression.replaceAllMapped(
      RegExp(r'([A-G][#b]?(?:m|maj|dim|aug|sus|add|\d)*(?:\/[A-G][#b]?)?)'),
          (Match match) {
        String chord = match.group(1)!;
        String transposed = _transposeChord(chord);
        print('Matched and transposed: "$chord" -> "$transposed"');
        return transposed;
      },
    );

    print('Final result: "$result"');
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadTransposeSettings();
    _loadBookmarkStatus();
  }

  Future<void> _loadTransposeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTranspose = prefs.getInt('transpose_${widget.song.id}') ?? 0;
      setState(() {
        _transposeSteps = savedTranspose;
      });
    } catch (e) {
      print('Error loading transpose settings: $e');
    }
  }

  Future<void> _saveTransposeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('transpose_${widget.song.id}', _transposeSteps);
    } catch (e) {
      print('Error saving transpose settings: $e');
    }
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkedSongs = prefs.getStringList('bookmarked_songs') ?? [];
      setState(() {
        _isBookmarked = bookmarkedSongs.contains(widget.song.id);
      });
    } catch (e) {
      print('Error loading bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> bookmarkedSongs = prefs.getStringList('bookmarked_songs') ?? [];
      if (_isBookmarked) {
        bookmarkedSongs.remove(widget.song.id);
        setState(() {
          _isBookmarked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from bookmarks'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        bookmarkedSongs.add(widget.song.id);
        setState(() {
          _isBookmarked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to bookmarks'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
      await prefs.setStringList('bookmarked_songs', bookmarkedSongs);
    } catch (e) {
      print('Error toggling bookmark: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    return Scaffold(
      backgroundColor: AppColors.lightGray1,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and controls
            Container(
              color: AppColors.lightGray1, // Match the background color
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.black,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${widget.song.title} – ${widget.song.creator}',
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isBookmarked ? Colors.amber : AppColors.lightGray2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: _isBookmarked ? AppColors.white : AppColors.black,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_fontScale < 2.0) {
                              _fontScale += 0.2;
                            } else {
                              _fontScale = 1.0;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _fontScale > 1.0 ? AppColors.black : AppColors.lightGray2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.text_fields,
                                color: _fontScale > 1.0 ? AppColors.white : AppColors.black,
                                size: 16,
                              ),
                              if (_fontScale > 1.0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${(_fontScale * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              FadePageRoute(builder: (_) => EditSongPage(song: widget.song)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Toggle buttons
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.lightGray2,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showChords = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showChords ? AppColors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Chords',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _showChords ? AppColors.white : AppColors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showChords = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showChords ? AppColors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Lyrics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_showChords ? AppColors.white : AppColors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Transpose controls
            if (_showChords) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.lightGray1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.lightGray2,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _updateTranspose(-1),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _transposeSteps < 0 ? AppColors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: _transposeSteps < 0 ? AppColors.white : AppColors.black,
                          size: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              'Transpose',
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _transposeSteps == 0
                                  ? 'Original'
                                  : '${_transposeSteps > 0 ? '+' : ''}$_transposeSteps',
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _updateTranspose(1),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _transposeSteps > 0 ? AppColors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add,
                          color: _transposeSteps > 0 ? AppColors.white : AppColors.black,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showChords) ...[
                      for (final section in widget.song.sectionOrder)
                        if (widget.song.chords[section]?.trim().isNotEmpty ?? false)
                          Container(
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      section.toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 12 * _fontScale,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: AppColors.lightGray2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _transposedChords[section]!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 16 * _fontScale,
                                    color: AppColors.black,
                                    height: 1.8,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ] else ...[
                      // Updated lyrics section with consistent design
                      // --- LYRICS: use lyricsOrder from the DB instead of sectionOrder ---
                      for (final section in widget.song.lyricsOrder)
                        if (widget.song.lyrics[section]?.trim().isNotEmpty ?? false)
                          Container(
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      section.toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 12 * _fontScale,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: AppColors.lightGray2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.song.lyrics[section]!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 16 * _fontScale,
                                    color: AppColors.black,
                                    height: 1.8,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      if (widget.song.lyricsOrder.isEmpty ||
                          !widget.song.lyricsOrder.any((section) =>
                          widget.song.lyrics.containsKey(section) &&
                              widget.song.lyrics[section]!.isNotEmpty))
                        ...widget.song.lyrics.entries.map((entry) =>
                            Container(
                              margin: const EdgeInsets.only(bottom: 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.value.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Text(
                                          entry.key.toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 12 * _fontScale,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: AppColors.lightGray2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 16 * _fontScale,
                                        color: AppColors.black,
                                        height: 1.8,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ).toList(),


                      // Fallback: If no sections match sectionOrder, display all lyrics with consistent design
                      if (widget.song.sectionOrder.isEmpty ||
                          !widget.song.sectionOrder.any((section) =>
                          widget.song.lyrics.containsKey(section) &&
                              widget.song.lyrics[section]!.isNotEmpty))
                        ...widget.song.lyrics.entries.map((entry) =>
                            Container(
                              margin: const EdgeInsets.only(bottom: 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.value.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Text(
                                          entry.key.toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 12 * _fontScale,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: AppColors.lightGray2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 16 * _fontScale,
                                        color: AppColors.black,
                                        height: 1.8,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ).toList(),
                    ],
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}