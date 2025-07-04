import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/songs.dart';
import '../services/song_repository.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override
  State<EditSongPage> createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  late final TextEditingController _title;
  late final TextEditingController _chords;
  late final TextEditingController _lyrics;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.song.title);
    _chords = TextEditingController(text: widget.song.chords);
    _lyrics = TextEditingController(text: widget.song.lyrics);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SongRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Song")),
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
              final updated = Song(
                id: widget.song.id,
                title: _title.text.trim(),
                chords: _chords.text.trim(),
                lyrics: _lyrics.text.trim(),
              );
              await repo.updateSong(updated);
              Navigator.pop(context);
            },
            child: const Text("Update Song"),
          )
        ]),
      ),
    );
  }
}
