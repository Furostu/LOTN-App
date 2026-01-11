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
  final List<Song>? songList; // Optional: list of songs for swipe navigation
  final int? initialIndex; // Optional: initial index in songList

  const SongDetailPage({
    super.key,
    required this.song,
    this.songList,
    this.initialIndex,
  });

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  bool _showChords = true;
  double _fontScale = 1.0;
  int _transposeSteps = 0;
  bool _isBookmarked = false;
  late PageController _pageController;
  late int _currentIndex;
  late Song _currentSong;

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

  @override
  void initState() {
    super.initState();

    // Initialize current song
    _currentSong = widget.song;

    // Initialize page controller if we have a list of songs
    if (widget.songList != null && widget.songList!.isNotEmpty) {
      _currentIndex = widget.initialIndex ?? _findSongIndex(widget.song);
      _pageController = PageController(initialPage: _currentIndex);
    } else {
      _currentIndex = 0;
      _pageController = PageController();
    }

    _loadTransposeSettings();
    _loadBookmarkStatus();
  }

  int _findSongIndex(Song song) {
    if (widget.songList == null) return 0;
    return widget.songList!.indexWhere((s) => s.id == song.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Transpose a single chord
  String _transposeChord(String chord, int transposeSteps) {
    if (transposeSteps == 0) return chord;

    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      String mainChord = _transposeSingleChord(parts[0], transposeSteps);
      String bassChord = _transposeSingleChord(parts[1], transposeSteps);
      return '$mainChord/$bassChord';
    }
    return _transposeSingleChord(chord, transposeSteps);
  }

  String _transposeSingleChord(String chord, int transposeSteps) {
    if (transposeSteps == 0 || chord.isEmpty) return chord;

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

    // Convert flat notes to sharp equivalents
    if (_enharmonicEquivalents.containsKey(rootNote)) {
      rootNote = _enharmonicEquivalents[rootNote]!;
    }

    // Find the index in chromatic scale
    int currentIndex = _chromaticScale.indexOf(rootNote);

    if (currentIndex == -1) {
      return chord; // Return original if not found
    }

    // Calculate new index with proper modulo handling
    int newIndex = (currentIndex + transposeSteps) % 12;
    if (newIndex < 0) newIndex += 12;

    return _chromaticScale[newIndex] + suffix;
  }

  void _updateTranspose(int change) {
    setState(() {
      _transposeSteps += change;
    });
    _saveTransposeSettings(_currentSong);
  }

  Map<String, String> _getTransposedChords(Song song, int transposeSteps) {
    if (transposeSteps == 0) return song.chords;
    Map<String, String> transposed = {};
    song.chords.forEach((key, value) {
      transposed[key] = _transposeChordProgression(value, transposeSteps);
    });
    return transposed;
  }

  String _transposeChordProgression(String chordProgression, int transposeSteps) {
    if (transposeSteps == 0) return chordProgression;

    // Updated regex to better match chord patterns in your format
    return chordProgression.replaceAllMapped(
      RegExp(r'([A-G][#b]?(?:m|maj|dim|aug|sus|add|\d)*(?:\/[A-G][#b]?)?)'),
          (Match match) {
        String chord = match.group(1)!;
        return _transposeChord(chord, transposeSteps);
      },
    );
  }

  Future<void> _loadTransposeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTranspose = prefs.getInt('transpose_${_currentSong.id}') ?? 0;
      setState(() {
        _transposeSteps = savedTranspose;
      });
    } catch (e) {
      print('Error loading transpose settings: $e');
    }
  }

  Future<void> _saveTransposeSettings(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('transpose_${song.id}', _transposeSteps);
    } catch (e) {
      print('Error saving transpose settings: $e');
    }
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkedSongs = prefs.getStringList('bookmarked_songs') ?? [];
      setState(() {
        _isBookmarked = bookmarkedSongs.contains(_currentSong.id);
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
        bookmarkedSongs.remove(_currentSong.id);
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
        bookmarkedSongs.add(_currentSong.id);
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

  Widget _buildSongDetailContent(Song song) {
    final transposedChords = _getTransposedChords(song, _transposeSteps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showChords) ...[
          for (final section in song.sectionOrder)
            if (song.chords[section]?.trim().isNotEmpty ?? false)
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
                      transposedChords[section]!,
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
          for (final section in song.lyricsOrder)
            if (song.lyrics[section]?.trim().isNotEmpty ?? false)
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
                      song.lyrics[section]!,
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
          if (song.lyricsOrder.isEmpty ||
              !song.lyricsOrder.any((section) =>
              song.lyrics.containsKey(section) &&
                  song.lyrics[section]!.isNotEmpty))
            ...song.lyrics.entries.map((entry) => Container(
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
            )).toList(),
        ],
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSongDetailPage(Song song) {
    return Scaffold(
      backgroundColor: AppColors.lightGray1,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and controls
            Container(
              color: AppColors.lightGray1,
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
                      '${song.title} – ${song.creator}',
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
                      if (context.read<AuthService>().isAdmin) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              FadePageRoute(
                                builder: (_) => EditSongPage(song: song),
                              ),
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
                child: _buildSongDetailContent(song),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we have a list of songs for swipe navigation, use PageView
    if (widget.songList != null && widget.songList!.length > 1) {
      return PageView.builder(
        controller: _pageController,
        itemCount: widget.songList!.length,
        onPageChanged: (index) async {
          final newSong = widget.songList![index];
          setState(() {
            _currentIndex = index;
            _currentSong = newSong;
            // Reset state for new song
            _fontScale = 1.0;
            _transposeSteps = 0;
            _showChords = true;
          });

          // Load settings for the new song
          await _loadTransposeSettings();
          await _loadBookmarkStatus();
        },
        itemBuilder: (context, index) {
          final song = widget.songList![index];
          return _buildSongDetailPage(song);
        },
      );
    }

    // Otherwise, just show the single song
    return _buildSongDetailPage(widget.song);
  }
}