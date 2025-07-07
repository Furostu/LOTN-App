import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/songs.dart';
import '../Services/album_repository.dart';
import '../Services/auth_service.dart';
import '../Services/song_repository.dart';
import '../Models/album.dart';
import '../transition.dart';
import 'song_list_page.dart';
import 'bookmark_page.dart';
import '../Widgets/bottom_navbar.dart';
import 'album_detail_page.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  int _currentNavIndex = 1;
  bool _isSelectionMode = false;
  Set<String> _selectedAlbumIds = <String>{};
  bool _isGeneratingAlbums = false;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  String _searchQuery = '';

  static const Color black = Color(0xFF000000);
  static const Color darkGray1 = Color(0xFF1F1F1F);
  static const Color darkGray2 = Color(0xFF242424);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray1 = Color(0xFFF2F2F2);
  static const Color lightGray2 = Color(0xFFE2E2E2);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == _currentNavIndex) return;
    Widget dest;
    switch (index) {
      case 0:
        dest = const SongListPage(initialIndex: 0);
        break;
      case 1:
        return;
      case 2:
        dest = const BookmarkPage();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      FadePageRoute(builder: (_) => dest),
    );
    setState(() => _currentNavIndex = index);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedAlbumIds.clear();
    });
  }

  void _toggleAlbumSelection(String albumId) {
    setState(() {
      if (_selectedAlbumIds.contains(albumId)) {
        _selectedAlbumIds.remove(albumId);
      } else {
        _selectedAlbumIds.add(albumId);
      }
    });
  }

  void _selectAll(List<Album> albums) {
    setState(() {
      _selectedAlbumIds = albums.map((a) => a.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAlbumIds.clear();
    });
  }

  void _confirmDeleteSelected(List<Album> albums) {
    final selectedAlbums = albums.where((a) => _selectedAlbumIds.contains(a.id)).toList();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.6),
        barrierDismissible: false,
        pageBuilder: (c, a1, a2) => _CustomMultiDeleteDialog(
          albums: selectedAlbums,
          onDelete: () {
            final repo = context.read<AlbumRepository>();
            for (final id in _selectedAlbumIds) repo.deleteAlbum(id);
            Navigator.of(context).pop();
            _toggleSelectionMode();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (c, anim, secAnim, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: child,
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.6),
        barrierDismissible: true,
        pageBuilder: (c, a1, a2) => _CustomAddAlbumDialog(
          onCreateAlbum: (name) {
            context.read<AlbumRepository>().addAlbum(name);
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (c, anim, secAnim, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _generateArtistAlbums() async {
    setState(() => _isGeneratingAlbums = true);
    try {
      final songRepo = context.read<SongRepository>();
      final albumRepo = context.read<AlbumRepository>();
      final songs = await songRepo.getAllSongs();
      final existingAlbums = await albumRepo.getAllAlbums();

      final Map<String, List<Song>> creatorSongs = {};
      for (final song in songs) {
        final creator = song.creator?.trim() ?? 'Unknown';
        if (creator.isNotEmpty && creator != 'Unknown') {
          creatorSongs.putIfAbsent(creator, () => []).add(song);
        }
      }

      int albumsCreated = 0;
      for (final entry in creatorSongs.entries) {
        final creator = entry.key;
        final creatorSongList = entry.value;
        if (creatorSongList.length >= 2) {
          final existingAlbum = existingAlbums.firstWhere(
                (album) => album.name.toLowerCase() == creator.toLowerCase(),
            orElse: () => Album(id: '', name: '', songIds: []),
          );
          if (existingAlbum.id.isEmpty) {
            final songIds = creatorSongList.map((song) => song.id).toList();
            await albumRepo.addAlbumWithSongs(creator, songIds);
            albumsCreated++;
          } else {
            final newSongIds = creatorSongList
                .map((song) => song.id)
                .where((id) => !existingAlbum.songIds.contains(id))
                .toList();
            if (newSongIds.isNotEmpty) {
              await albumRepo.addSongsToAlbum(existingAlbum.id, newSongIds);
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              albumsCreated > 0
                  ? 'Created $albumsCreated creator album${albumsCreated == 1 ? '' : 's'}'
                  : 'All creator albums are up to date',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating albums: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAlbums = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AlbumRepository>();
    final isAdmin = context.watch<AuthService>().isAdmin;
    return Scaffold(
      backgroundColor: lightGray1,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.album, color: black, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSelectionMode ? 'Select Albums' : 'Albums',
                          style: const TextStyle(
                            color: black,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSelectionMode
                              ? '${_selectedAlbumIds.length} selected'
                              : 'Your custom song collections',
                          style: TextStyle(
                            color: darkGray2,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSelectionMode) ...[
                    GestureDetector(
                      onTap: _toggleSelectionMode,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lightGray2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close, color: black, size: 16),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: _isGeneratingAlbums ? null : _generateArtistAlbums,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isGeneratingAlbums ? lightGray2 : Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _isGeneratingAlbums
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(white),
                          ),
                        )
                            : const Icon(Icons.auto_awesome, color: white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isAdmin) ...[
                      GestureDetector(
                        onTap: _toggleSelectionMode,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: lightGray2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.checklist, color: black, size: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: () => _showAddDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: white, size: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isSearchFocused ? black : lightGray2,
                    width: _isSearchFocused ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isSearchFocused
                          ? black.withOpacity(0.2)
                          : black.withOpacity(0.1),
                      blurRadius: _isSearchFocused ? 14 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    setState(() => _isSearchFocused = hasFocus);
                  },
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search albums...',
                      hintStyle: TextStyle(
                        color: darkGray2.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.search,
                          color: _isSearchFocused ? black : darkGray2,
                          size: 22,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: darkGray2,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.clear,
                            color: white,
                            size: 16,
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isSelectionMode) ...[
              const SizedBox(height: 16),
              StreamBuilder<List<Album>>(
                stream: repo.albumsStream,
                builder: (context, snap) {
                  final albums = snap.data ?? [];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightGray2, width: 1),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _selectAll(albums),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: lightGray2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: lightGray2, width: 1),
                            ),
                            child: const Text(
                              'Select All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: black,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _clearSelection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: lightGray2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: lightGray2, width: 1),
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: black,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _selectedAlbumIds.isNotEmpty
                              ? () => _confirmDeleteSelected(albums)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedAlbumIds.isNotEmpty ? black : lightGray2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: _selectedAlbumIds.isNotEmpty
                                      ? white
                                      : Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedAlbumIds.isNotEmpty
                                        ? white
                                        : Colors.white70,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<Album>>(
                stream: repo.albumsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final albums = snap.data ?? [];
                  final filtered = _searchQuery.isEmpty
                      ? albums
                      : albums
                      .where((a) => a.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                      .toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No albums found', style: TextStyle(color: Colors.black54)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _AlbumCard(
                      album: filtered[i],
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedAlbumIds.contains(filtered[i].id),
                      onToggleSelection: () => _toggleAlbumSelection(filtered[i].id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const _AlbumCard({
    required this.album,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelection,
  });

  static const Color black = Color(0xFF000000);
  static const Color darkGray2 = Color(0xFF242424);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray2 = Color(0xFFE2E2E2);

  @override
  Widget build(BuildContext context) {
    final count = album.songIds.length;
    final isAdmin = context.watch<AuthService>().isAdmin;
    final repo = context.read<AlbumRepository>();

    void _confirmDelete() {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.6),
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return _CustomDeleteDialog(
              album: album,
              onDelete: () {
                repo.deleteAlbum(album.id);
                Navigator.of(context).pop();
              },
              onCancel: () => Navigator.of(context).pop(),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? black : lightGray2,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.2 : 0.08),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isSelectionMode
              ? onToggleSelection
              : () {
            Navigator.of(context).push(
              FadePageRoute(
                builder: (_) => AlbumDetailPage(album: album),
              ),
            );
          },
          onLongPress: isAdmin && !isSelectionMode ? _confirmDelete : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isSelectionMode)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? black : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? black : darkGray2,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      color: white,
                      size: 14,
                    )
                        : null,
                  ),
                if (isSelectionMode) const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [darkGray2, black],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  width: 48,
                  height: 48,
                  child: const Icon(Icons.album, color: white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count song${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: darkGray2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSelectionMode)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: lightGray2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: darkGray2,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomAddAlbumDialog extends StatefulWidget {
  final Function(String) onCreateAlbum;
  final VoidCallback onCancel;

  const _CustomAddAlbumDialog({
    required this.onCreateAlbum,
    required this.onCancel,
  });

  @override
  State<_CustomAddAlbumDialog> createState() => _CustomAddAlbumDialogState();
}

class _CustomAddAlbumDialogState extends State<_CustomAddAlbumDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_validateInput);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    final isValid = _controller.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  void _handleCreate() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onCreateAlbum(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.album_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Create New Album',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Give your new album collection a memorable name',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focusNode.hasFocus ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter album name',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                      letterSpacing: -0.3,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _isValid ? _handleCreate() : null,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isValid ? _handleCreate : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _isValid ? Colors.black : Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Create Album',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _isValid ? Colors.white : Colors.white70,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
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
}

class _CustomDeleteDialog extends StatelessWidget {
  final Album album;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _CustomDeleteDialog({
    required this.album,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Delete Album',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "${album.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
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
}

class _CustomMultiDeleteDialog extends StatelessWidget {
  final List<Album> albums;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _CustomMultiDeleteDialog({
    required this.albums,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Delete Albums',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete ${albums.length} album${albums.length == 1 ? '' : 's'}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Delete All',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
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
}
