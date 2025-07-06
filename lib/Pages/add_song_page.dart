import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/song_repository.dart';
import '../Models/songs.dart';

class AddSongPage extends StatefulWidget {
  const AddSongPage({super.key});

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> with TickerProviderStateMixin {
  final _title = TextEditingController();
  final _lyrics = TextEditingController();
  final _creator = TextEditingController(); // Added creator controller
  final Map<String, TextEditingController> _chordSections = {};
  final List<String> _sectionOrder = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> defaultSections = [
    'Intro',
    'Verse',
    'Chorus',
    'Verse 2',
    'Bridge',
    'Outro',
  ];

  final List<String> predefinedSections = [
    'Verse',
    'Verse 2',
    'Verse 3',
    'Pre Chorus',
    'Chorus',
    'Instrumental / Bridge',
    'Instrumental',
    'Bridge',
    'Bridge 2',
    'Transition',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    for (final section in defaultSections) {
      _chordSections[section] = TextEditingController();
      _sectionOrder.add(section);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addNewSection() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Section',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose from common sections:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: predefinedSections.length,
                  itemBuilder: (context, index) {
                    final section = predefinedSections[index];
                    final isAlreadyAdded = _chordSections.containsKey(section);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isAlreadyAdded
                              ? null
                              : () {
                            setState(() {
                              _chordSections[section] = TextEditingController();
                              _sectionOrder.add(section);
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isAlreadyAdded ? Colors.grey[200] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAlreadyAdded ? Colors.grey[300]! : Colors.grey[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    section,
                                    style: TextStyle(
                                      color: isAlreadyAdded ? Colors.grey[500] : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isAlreadyAdded)
                                  Icon(Icons.check_circle, color: Colors.grey[400], size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Or create a custom section:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Custom section name',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
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
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Add Custom', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Create Song',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Song Title'),
                      const SizedBox(height: 12),
                      _buildModernTextField(controller: _title, hintText: 'Enter song title', maxLines: 1),

                      const SizedBox(height: 20),
                      _buildSectionHeader('Creator'), // New Creator Field
                      const SizedBox(height: 12),
                      _buildModernTextField(controller: _creator, hintText: 'Enter creator name', maxLines: 1),

                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('Chord Sections'),
                          GestureDetector(
                            onTap: _addNewSection,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._sectionOrder.map((section) {
                        final controller = _chordSections[section]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(section,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3)),
                                  GestureDetector(
                                    onTap: () => _removeSection(section),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Icon(Icons.close, color: Colors.grey[600], size: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextField(
                                  controller: controller,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    color: Colors.black,
                                    height: 1.6,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter chords...',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                  maxLines: null,
                                  minLines: 3,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                      _buildSectionHeader('Lyrics'),
                      const SizedBox(height: 12),
                      _buildModernTextField(controller: _lyrics, hintText: 'Enter song lyrics...', maxLines: null, minLines: 8),

                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))],
                        ),
                        child: TextButton(
                          onPressed: () async {
                            final chords = {
                              for (final section in _sectionOrder)
                                if (_chordSections[section]!.text.trim().isNotEmpty)
                                  section: _chordSections[section]!.text.trim(),
                            };

                            final song = Song(
                              id: '',
                              title: _title.text.trim(),
                              chords: chords,
                              sectionOrder: _sectionOrder,
                              lyrics: _lyrics.text.trim(),
                              creator: _creator.text.trim(), // Save creator here
                            );

                            await repo.addSong(song);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'Save Song',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    int? maxLines,
    int? minLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          color: Colors.black,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        maxLines: maxLines,
        minLines: minLines,
      ),
    );
  }
}
