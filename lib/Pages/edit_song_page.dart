import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/songs.dart';
import '../Services/song_repository.dart';

class EditSongPage extends StatefulWidget {
  final Song song;
  const EditSongPage({super.key, required this.song});

  @override
  State<EditSongPage> createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  late final TextEditingController _title;
  late final TextEditingController _lyrics;
  late final TextEditingController _creator; // ✅ New field

  final Map<String, TextEditingController> _chordSections = {};
  final List<String> _sectionOrder = [];

  final List<String> defaultSections = [
    'Intro',
    'Verse',
    'Chorus',
    'Verse 2 (Optional)',
    'Instrumental (Optional)',
    'Bridge',
    'Transition (Optional)',
    'Chorus (Transition) (Optional)',
  ];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.song.title);
    _lyrics = TextEditingController(text: widget.song.lyrics);
    _creator = TextEditingController(text: widget.song.creator); // ✅ Init

    final chordsMap = widget.song.chords;
    final order = widget.song.sectionOrder;

    for (final section in order) {
      _chordSections[section] = TextEditingController(text: chordsMap[section] ?? '');
      _sectionOrder.add(section);
    }

    for (final section in defaultSections) {
      if (!_chordSections.containsKey(section)) {
        _chordSections[section] = TextEditingController();
        _sectionOrder.add(section);
      }
    }
  }

  void _addNewSection() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Section'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Section Name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && !_chordSections.containsKey(name)) {
                setState(() {
                  _chordSections[name] = TextEditingController();
                  _sectionOrder.add(name);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeSection(String section) {
    setState(() {
      _chordSections.remove(section);
      _sectionOrder.remove(section);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SongRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Song")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _creator,
                decoration: const InputDecoration(labelText: 'Creator'), // ✅ Added creator input
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Chord Sections", style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _addNewSection,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Section',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sectionOrder.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _sectionOrder.removeAt(oldIndex);
                      _sectionOrder.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final section = _sectionOrder[index];
                    final controller = _chordSections[section]!;

                    return ListTile(
                      key: ValueKey(section),
                      title: TextField(
                        controller: controller,
                        decoration: InputDecoration(labelText: section),
                        maxLines: null,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeSection(section),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text("Lyrics", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _lyrics,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Edit lyrics',
                ),
                maxLines: null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final chords = {
                      for (final section in _sectionOrder)
                        if (_chordSections[section]!.text.trim().isNotEmpty)
                          section: _chordSections[section]!.text.trim()
                    };

                    final updated = Song(
                      id: widget.song.id,
                      title: _title.text.trim(),
                      chords: chords,
                      sectionOrder: _sectionOrder,
                      lyrics: _lyrics.text.trim(),
                      creator: _creator.text.trim(), // ✅ Save updated creator
                    );

                    await repo.updateSong(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Update Song"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
