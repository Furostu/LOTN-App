import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/song_repository.dart';
import '../Models/songs.dart';

class AddSongPage extends StatefulWidget {
  const AddSongPage({super.key});

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  final _title = TextEditingController();
  final _chords = TextEditingController();
  final _lyrics = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SongRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text("Add New Song")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: _chords, decoration: const InputDecoration(labelText: 'Chords')),
          Expanded(
            child: TextField(
              controller: _lyrics,
              decoration: const InputDecoration(labelText: 'Lyrics'),
              maxLines: null,
              expands: true,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final song = Song(
                id: '', // Firestore assigns it
                title: _title.text.trim(),
                chords: _chords.text.trim(),
                lyrics: _lyrics.text.trim(),
              );
              await repo.addSong(song);
              Navigator.pop(context);
            },
            child: const Text("Save Song"),
          )
        ]),
      ),
    );
  }
}
