import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/songs.dart';
import '../services/auth_service.dart';
import 'edit_song_page.dart';

class SongDetailPage extends StatelessWidget {
  final Song song;
  const SongDetailPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSongPage(song: song),
                ),
              ),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            '${song.chords}\n\n${song.lyrics}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
          ),
        ),
      ),
    );
  }
}
