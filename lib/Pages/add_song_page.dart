import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/song_repository.dart';
import '../Models/songs.dart';

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color darkGray1 = Color(0xFF1F1F1F);
  static const Color darkGray2 = Color(0xFF242424);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray1 = Color(0xFFF2F2F2);
  static const Color lightGray2 = Color(0xFFE2E2E2);
}

class AddSongPage extends StatefulWidget {
  const AddSongPage({super.key});

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> with TickerProviderStateMixin {
  final _title = TextEditingController();
  final _creator = TextEditingController();
  final Map<String, TextEditingController> _chordSections = {};
  final Map<String, TextEditingController> _lyricSections = {};
  final List<String> _sectionOrder = []; // Chord sections order
  final List<String> _lyricsOrder = []; // Lyric sections order
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedLanguage = 'English';
  String _selectedType = 'Fast Song';
  final List<String> _languageOptions = ['English', 'Tagalog'];
  final List<String> _typeOptions = ['Fast Song', 'Slow Song'];

  final List<String> chordDefaultSections = [
    'Intro',
    'Verse',
    'Pre Chorus',
    'Chorus',
    'Bridge',
    'Outro',
  ];

  final List<String> lyricDefaultSections = [
    'Verse',
    'Pre Chorus',
    'Chorus',
    'Verse 2',
    'Bridge',
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
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    // Initialize chord sections
    for (final section in chordDefaultSections) {
      _chordSections[section] = TextEditingController();
      _sectionOrder.add(section);
    }

    // Initialize lyric sections separately
    for (final section in lyricDefaultSections) {
      _lyricSections[section] = TextEditingController();
      _lyricsOrder.add(section);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _title.dispose();
    _creator.dispose();
    for (final controller in _chordSections.values) {
      controller.dispose();
    }
    for (final controller in _lyricSections.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewSection() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierColor: AppColors.black.withOpacity(0.8),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Chord Section',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose from common sections:',
                style: TextStyle(
                  color: AppColors.darkGray1,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.lightGray1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray2),
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
                              color: isAlreadyAdded ? AppColors.lightGray2 : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAlreadyAdded ? AppColors.lightGray2 : AppColors.lightGray1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    section,
                                    style: TextStyle(
                                      color: isAlreadyAdded ? AppColors.darkGray1.withOpacity(0.6) : AppColors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isAlreadyAdded)
                                  Icon(Icons.check_circle, color: AppColors.darkGray1.withOpacity(0.6), size: 20),
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
                  color: AppColors.darkGray1,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray2),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Custom section name',
                    hintStyle: TextStyle(color: AppColors.darkGray1),
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
                        foregroundColor: AppColors.darkGray1,
                        backgroundColor: AppColors.lightGray1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _removeChordSection(String section) {
    setState(() {
      _chordSections[section]?.dispose();
      _chordSections.remove(section);
      _sectionOrder.remove(section);
    });
  }

  void _addNewLyricSection() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierColor: AppColors.black.withOpacity(0.8),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Lyric Section',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose from common sections:',
                style: TextStyle(
                  color: AppColors.darkGray1,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.lightGray1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray2),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: predefinedSections.length,
                  itemBuilder: (context, index) {
                    final section = predefinedSections[index];
                    final isAlreadyAdded = _lyricSections.containsKey(section);
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
                              _lyricSections[section] = TextEditingController();
                              _lyricsOrder.add(section);
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isAlreadyAdded ? AppColors.lightGray2 : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAlreadyAdded ? AppColors.lightGray2 : AppColors.lightGray1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    section,
                                    style: TextStyle(
                                      color: isAlreadyAdded ? AppColors.darkGray1.withOpacity(0.6) : AppColors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isAlreadyAdded)
                                  Icon(Icons.check_circle, color: AppColors.darkGray1.withOpacity(0.6), size: 20),
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
                  color: AppColors.darkGray1,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray2),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Custom section name',
                    hintStyle: TextStyle(color: AppColors.darkGray1),
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
                        foregroundColor: AppColors.darkGray1,
                        backgroundColor: AppColors.lightGray1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isNotEmpty && !_lyricSections.containsKey(name)) {
                          setState(() {
                            _lyricSections[name] = TextEditingController();
                            _lyricsOrder.add(name);
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _removeLyricSection(String section) {
    setState(() {
      _lyricSections[section]?.dispose();
      _lyricSections.remove(section);
      _lyricsOrder.remove(section);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SongRepository>();
    return Scaffold(
      backgroundColor: AppColors.white,
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.lightGray2),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Create Song',
                        style: TextStyle(
                          color: AppColors.black,
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
                      _buildModernTextField(
                        controller: _title,
                        hintText: 'Enter song title',
                        maxLines: 1,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Creator'),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        controller: _creator,
                        hintText: 'Enter creator name',
                        maxLines: 1,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Language'),
                                const SizedBox(height: 12),
                                _buildDropdown(
                                  value: _selectedLanguage,
                                  options: _languageOptions,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLanguage = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Type'),
                                const SizedBox(height: 12),
                                _buildDropdown(
                                  value: _selectedType,
                                  options: _typeOptions,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('Chord Sections'),
                          GestureDetector(
                            onTap: _addNewSection,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._sectionOrder.map((section) {
                        final controller = _chordSections[section]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray1,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.lightGray2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    section,
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeChordSection(section),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.lightGray2),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: AppColors.darkGray1,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.lightGray2),
                                ),
                                child: TextField(
                                  controller: controller,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    color: AppColors.black,
                                    height: 1.6,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter chords...',
                                    hintStyle: TextStyle(color: AppColors.darkGray1),
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
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('Lyric Sections'),
                          GestureDetector(
                            onTap: _addNewLyricSection,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._lyricsOrder.map((section) {
                        final controller = _lyricSections[section]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray1,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.lightGray2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    section,
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeLyricSection(section),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.lightGray2),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: AppColors.darkGray1,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.lightGray2),
                                ),
                                child: TextField(
                                  controller: controller,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.black,
                                    height: 1.6,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter lyrics...',
                                    hintStyle: TextStyle(color: AppColors.darkGray1),
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
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () async {
                            final chords = {
                              for (final section in _sectionOrder)
                                if (_chordSections[section]!.text.trim().isNotEmpty)
                                  section: _chordSections[section]!.text.trim(),
                            };
                            final lyrics = {
                              for (final section in _lyricsOrder)
                                if (_lyricSections[section]!.text.trim().isNotEmpty)
                                  section: _lyricSections[section]!.text.trim(),
                            };
                            final song = Song(
                              id: '',
                              title: _title.text.trim(),
                              chords: chords,
                              sectionOrder: _sectionOrder,
                              lyrics: lyrics,
                              lyricsOrder: _lyricsOrder,
                              creator: _creator.text.trim(),
                              language: _selectedLanguage,
                              type: _selectedType,
                            );
                            await repo.addSong(song);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Save Song',
                            style: TextStyle(
                              color: AppColors.white,
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
        color: AppColors.black,
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
        color: AppColors.lightGray1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray2),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.black,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.darkGray1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        maxLines: maxLines,
        minLines: minLines,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.black),
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.white,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}