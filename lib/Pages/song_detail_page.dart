import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/songs.dart';
import '../Services/auth_service.dart';
import 'edit_song_page.dart';

class SongDetailPage extends StatefulWidget {
  final Song song;
  const SongDetailPage({super.key, required this.song});

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  bool _showChords = true;
  double _fontScale = 1.0;

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
                              MaterialPageRoute(builder: (_) => EditSongPage(song: widget.song)),
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

                                // Chords content
                                Text(
                                  widget.song.chords[section]!,
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