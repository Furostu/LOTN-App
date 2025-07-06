import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/song_repository.dart';
import '../Services/auth_service.dart';
import '../Models/songs.dart';
import '../Widgets/bottom_navbar.dart';
import '../transition.dart';
import 'album_page.dart';
import 'bookmark_page.dart';
import 'pin_page.dart';
import 'add_song_page.dart';
import 'song_detail_page.dart';

class SongListPage extends StatefulWidget {
  final int initialIndex;
  const SongListPage({super.key, this.initialIndex = 0});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchFocused = false;
  int _currentNavIndex = 0; // Add this for bottom navigation

  // Selection state for delete functionality
  bool _isSelectionMode = false;
  Set<String> _selectedSongs = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _filterSongs(List<Song> songs) {
    if (_searchQuery.isEmpty) return songs;

    return songs.where((song) {
      return song.title.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSongs.clear();
      }
    });
  }

  void _toggleSongSelection(String songId) {
    setState(() {
      if (_selectedSongs.contains(songId)) {
        _selectedSongs.remove(songId);
      } else {
        _selectedSongs.add(songId);
      }
    });
  }

  // Add this method to handle bottom navigation
  void _onNavItemTapped(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          FadePageRoute(builder: (_) => const AlbumsPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          FadePageRoute(builder: (_) => const BookmarkPage()),
        );
        break;
    }
  }

  // Add these methods for logout and delete confirmation dialogs
  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout from admin mode?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                auth.logout();
                Navigator.of(context).pop();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Updated delete confirmation dialog with custom styling
  void _showDeleteConfirmDialog(BuildContext context, SongRepository repo) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.6),
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return CustomSongDeleteDialog(  // This class needs to be created
            selectedCount: _selectedSongs.length,
            onDelete: () async {
              for (String songId in _selectedSongs) {
                await repo.deleteSong(songId);
              }
              _toggleSelectionMode();
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

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SongRepository>();
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with logo and menu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOTN',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Song Chords',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        color: Colors.white,
                        elevation: 20,
                        shadowColor: Colors.black.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.black12, width: 1),
                        ),
                        itemBuilder: (BuildContext context) => [
                          if (!auth.isAdmin)
                            PopupMenuItem<String>(
                              value: 'login',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.login,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Admin Login',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (auth.isAdmin)
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Logout Admin',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (auth.isAdmin)
                            PopupMenuItem<String>(
                              value: 'add_song',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Add Song',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (auth.isAdmin)
                            PopupMenuItem<String>(
                              value: 'delete_songs',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Delete Songs',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (String value) {
                          switch (value) {
                            case 'login':
                              Navigator.push(
                                context,
                                FadePageRoute(
                                  builder: (context) => const PinPage(),
                                ),
                              );
                              break;
                            case 'logout':
                              _showLogoutDialog(context, auth);
                              break;
                            case 'add_song':
                              Navigator.push(
                                context,
                                FadePageRoute(builder: (_) => const AddSongPage()),
                              );
                              break;
                            case 'delete_songs':
                              _toggleSelectionMode();
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isSearchFocused ? Colors.black : Colors.black12,
                        width: _isSearchFocused ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isSearchFocused = hasFocus;
                        });
                      },
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search songs...',
                          hintStyle: const TextStyle(
                            color: Colors.black38,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.search,
                              color: Colors.black54,
                              size: 22,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.clear,
                                color: Colors.white,
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
                ],
              ),
            ),
            // Selection Mode Top Bar
            if (_isSelectionMode && auth.isAdmin)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete,
                      color: Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedSongs.isEmpty
                            ? 'Select songs to delete'
                            : '${_selectedSongs.length} ${_selectedSongs.length == 1 ? 'song' : 'songs'} selected',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedSongs.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () => _showDeleteConfirmDialog(context, repo),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: _toggleSelectionMode,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Songs List
            Expanded(
              child: StreamBuilder<List<Song>>(
                stream: repo.songsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Loading songs...',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Something went wrong',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please try again later',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allSongs = snapshot.data ?? [];
                  final filteredSongs = _filterSongs(allSongs);

                  if (allSongs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.music_off,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No songs available',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            auth.isAdmin
                                ? 'Use the menu to add your first song!'
                                : 'Check back later for new songs',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredSongs.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.search_off,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No songs found',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try different keywords for "$_searchQuery"',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Status bar
                      if (!_isSelectionMode)
                        Container(
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: auth.isAdmin ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: auth.isAdmin ? Colors.black : Colors.black12,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                auth.isAdmin ? Icons.admin_panel_settings : Icons.library_music,
                                color: auth.isAdmin ? Colors.white : Colors.black,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                auth.isAdmin
                                    ? 'Admin Mode Active'
                                    : _searchQuery.isNotEmpty
                                    ? '${filteredSongs.length} of ${allSongs.length} songs'
                                    : '${allSongs.length} ${allSongs.length == 1 ? 'song' : 'songs'} available',
                                style: TextStyle(
                                  color: auth.isAdmin ? Colors.white : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Songs list
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20), // Add bottom padding for navbar
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredSongs.length,
                            itemBuilder: (context, index) {
                              final song = filteredSongs[index];
                              final isSelected = _selectedSongs.contains(song.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12), // Reduced from 16 to 12
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16), // Reduced from 20 to 16
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.black12,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06), // Reduced shadow opacity
                                      blurRadius: 12, // Reduced from 16 to 12
                                      offset: const Offset(0, 3), // Reduced from 4 to 3
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      if (_isSelectionMode && auth.isAdmin) {
                                        _toggleSongSelection(song.id);
                                      } else {
                                        Navigator.push(
                                          context,
                                          FadePageRoute(
                                            builder: (_) => SongDetailPage(song: song),
                                          ),
                                        );
                                      }
                                    },
                                    onLongPress: auth.isAdmin
                                        ? () {
                                      if (!_isSelectionMode) {
                                        setState(() {
                                          _isSelectionMode = true;
                                          _selectedSongs.add(song.id);
                                        });
                                      }
                                    }
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(18), // Reduced from 24 to 18
                                      child: Row(
                                        children: [
                                          // Selection indicator or music icon
                                          if (_isSelectionMode && auth.isAdmin)
                                            Container(
                                              width: 48, // Reduced from 60 to 48
                                              height: 48, // Reduced from 60 to 48
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.black : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(14), // Reduced from 18 to 14
                                                border: Border.all(
                                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                isSelected ? Icons.check : Icons.music_note,
                                                color: isSelected ? Colors.white : Colors.grey.shade600,
                                                size: 24, // Reduced from 30 to 24
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 48, // Reduced from 60 to 48
                                              height: 48, // Reduced from 60 to 48
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(14), // Reduced from 18 to 14
                                              ),
                                              child: const Icon(
                                                Icons.music_note,
                                                color: Colors.white,
                                                size: 24, // Reduced from 30 to 24
                                              ),
                                            ),
                                          const SizedBox(width: 16), // Reduced from 20 to 16
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${song.title}  –  ${song.creator}',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 3), // Reduced from 4 to 3
                                                Text(
                                                  _isSelectionMode && auth.isAdmin
                                                      ? 'Tap to select/deselect'
                                                      : 'Tap to view chords',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13, // Reduced from 14 to 13
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!_isSelectionMode)
                                            Container(
                                              padding: const EdgeInsets.all(7), // Reduced from 8 to 7
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
                                              ),
                                              child: const Icon(
                                                Icons.chevron_right,
                                                color: Colors.white,
                                                size: 18, // Reduced from 20 to 18
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Add the bottom navigation bar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

class CustomSongDeleteDialog extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const CustomSongDeleteDialog({
    super.key,
    required this.selectedCount,
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
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              const Text(
                'Delete Songs?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),

              // Song count highlight
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  '$selectedCount ${selectedCount == 1 ? 'song' : 'songs'} selected',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                'This action cannot be undone. The selected songs will be permanently removed from the collection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 36),

              // Buttons
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
                          color: Colors.black,
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