import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/songs.dart';
import '../Services/auth_service.dart';
import '../transition.dart';
import 'edit_song_page.dart';
import 'bookmark_page.dart';

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
    'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#'
  };

  // Transpose a single chord
  String _transposeChord(String chord) {
    if (_transposeSteps == 0) return chord;

    // Handle slash chords (e.g., E/G#m)
    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      String mainChord = _transposeSingleChord(parts[0]);
      String bassChord = _transposeSingleChord(parts[1]);
      return '$mainChord/$bassChord';
    }

    return _transposeSingleChord(chord);
  }

  // Helper method to transpose a single chord without slash
  String _transposeSingleChord(String chord) {
    if (_transposeSteps == 0) return chord;

    // Handle complex chords by extracting the root note
    String rootNote = '';
    String suffix = '';

    // Find the root note (can be 1 or 2 characters)
    if (chord.length >= 2 && (chord[1] == '#' || chord[1] == 'b')) {
      rootNote = chord.substring(0, 2);
      suffix = chord.substring(2);
    } else if (chord.isNotEmpty) {
      rootNote = chord.substring(0, 1);
      suffix = chord.substring(1);
    }

    // Convert enharmonic equivalents
    if (_enharmonicEquivalents.containsKey(rootNote)) {
      rootNote = _enharmonicEquivalents[rootNote]!;
    }

    // Find the index of the root note
    int currentIndex = _chromaticScale.indexOf(rootNote);
    if (currentIndex == -1) return chord; // Return original if not found

    // Calculate new index with transposition
    int newIndex = (currentIndex + _transposeSteps) % 12;
    if (newIndex < 0) newIndex += 12;

    return _chromaticScale[newIndex] + suffix;
  }

  // Transpose all chords in a chord progression string while preserving formatting
  String _transposeChordProgression(String chordProgression) {
    if (_transposeSteps == 0) return chordProgression;

    // Use regex to find and replace only the chord patterns while preserving everything else
    return chordProgression.replaceAllMapped(
      RegExp(r'\b([A-G][#b]?(?:m|maj|dim|aug|sus|add|\d)*(?:\/[A-G][#b]?)?)\b'),
          (Match match) {
        String chord = match.group(1)!;
        return _transposeChord(chord);
      },
    );
  }

  // Update transpose and save to phone
  void _updateTranspose(int change) {
    setState(() {
      _transposeSteps += change;
    });
    _saveTransposeSettings();
  }

  // Get the transposed chords map
  Map<String, String> get _transposedChords {
    if (_transposeSteps == 0) return widget.song.chords;

    Map<String, String> transposed = {};
    widget.song.chords.forEach((key, value) {
      transposed[key] = _transposeChordProgression(value);
    });
    return transposed;
  }

  @override
  void initState() {
    super.initState();
    _loadTransposeSettings();
    _loadBookmarkStatus();
  }

  // Load saved transpose setting for this specific song
  Future<void> _loadTransposeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTranspose = prefs.getInt('transpose_${widget.song.id}') ?? 0;
      setState(() {
        _transposeSteps = savedTranspose;
      });
    } catch (e) {
      // If there's an error loading, just keep default value
      print('Error loading transpose settings: $e');
    }
  }

  // Save transpose setting for this specific song
  Future<void> _saveTransposeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('transpose_${widget.song.id}', _transposeSteps);
    } catch (e) {
      print('Error saving transpose settings: $e');
    }
  }

  // Load bookmark status for this song
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

  // Toggle bookmark status
  Future<void> _toggleBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> bookmarkedSongs = prefs.getStringList('bookmarked_songs') ?? [];

      if (_isBookmarked) {
        // Remove from bookmarks
        bookmarkedSongs.remove(widget.song.id);
        setState(() {
          _isBookmarked = false;
        });

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from bookmarks'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.grey[800],
          ),
        );
      } else {
        // Add to bookmarks
        bookmarkedSongs.add(widget.song.id);
        setState(() {
          _isBookmarked = true;
        });

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to bookmarks'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green[600],
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and controls
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black87,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title
                  Expanded(
                    child: Text(
                      widget.song.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // Controls row
                  Row(
                    children: [
                      // Bookmark button
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isBookmarked ? Colors.amber : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: _isBookmarked ? Colors.white : Colors.black54,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Font size control
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
                            color: _fontScale > 1.0 ? Colors.black : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.text_fields,
                                color: _fontScale > 1.0 ? Colors.white : Colors.black54,
                                size: 16,
                              ),
                              if (_fontScale > 1.0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${(_fontScale * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Edit button for admin
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
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black12,
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
                          color: _showChords ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Chords',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _showChords ? Colors.white : Colors.black54,
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
                          color: !_showChords ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Lyrics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_showChords ? Colors.white : Colors.black54,
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

            // Transpose controls (only show when chords are visible)
            if (_showChords) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black12,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Transpose down button
                    GestureDetector(
                      onTap: () => _updateTranspose(-1),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _transposeSteps < 0 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: _transposeSteps < 0 ? Colors.white : Colors.black54,
                          size: 16,
                        ),
                      ),
                    ),

                    // Transpose info
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              'Transpose',
                              style: TextStyle(
                                color: Colors.black54,
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
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Transpose up button
                    GestureDetector(
                      onTap: () => _updateTranspose(1),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _transposeSteps > 0 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add,
                          color: _transposeSteps > 0 ? Colors.white : Colors.black54,
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
                      // Chords section - clean layout
                      for (final section in widget.song.sectionOrder)
                        if (widget.song.chords[section]?.trim().isNotEmpty ?? false)
                          Container(
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section header with subtle line
                                Row(
                                  children: [
                                    Text(
                                      section.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12 * _fontScale,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey[200],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Chords content (transposed)
                                Text(
                                  _transposedChords[section]!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 16 * _fontScale,
                                    color: Colors.black87,
                                    height: 1.8,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ] else ...[
                      // Lyrics section - clean layout
                      Container(
                        child: Text(
                          widget.song.lyrics,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16 * _fontScale,
                            color: Colors.black87,
                            height: 1.8,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
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