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

// Add language filter enum
enum SongLanguageFilter { all, tagalog, english }

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
  int _currentNavIndex = 0;

  // Selection state for delete functionality
  bool _isSelectionMode = false;
  Set<String> _selectedSongs = <String>{};

  // Language filter state
  SongLanguageFilter _languageFilter = SongLanguageFilter.all;
  SongTypeFilter _typeFilter = SongTypeFilter.all;

  // New color palette
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
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SongRepository>();
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: lightGray1,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [darkGray1, darkGray2],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with logo and menu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12), // Adjust padding as needed
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png', // Path to your logo image
                          width: 48, // Adjust width as needed
                          height: 48, // Adjust height as needed
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
                                color: white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                            Text(
                              'Song Chords Collection',
                              style: TextStyle(
                                color: lightGray2,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(10),
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
                          child: Icon(
                            Icons.more_vert,
                            color: black,
                            size: 24,
                          ),
                        ),
                        color: white,
                        elevation: 20,
                        shadowColor: black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: lightGray2, width: 1),
                        ),
                        itemBuilder: (BuildContext context) => [
                          if (!auth.isAdmin)
                            PopupMenuItem<String>(
                              value: 'login',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: darkGray2,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.login,
                                      color: white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Admin Login',
                                    style: TextStyle(
                                      color: black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: darkGray2,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.logout,
                                      color: white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Logout Admin',
                                    style: TextStyle(
                                      color: black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: darkGray2,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add Song',
                                    style: TextStyle(
                                      color: black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: darkGray2,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete Songs',
                                    style: TextStyle(
                                      color: black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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

                  // Filter dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced from 16 to 12
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(16), // Reduced from 20 to 16
                            border: Border.all(color: lightGray2, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: black.withOpacity(0.1),
                                blurRadius: 6, // Reduced from 8 to 6
                                offset: const Offset(0, 3), // Reduced from 4 to 3
                              ),
                            ],
                          ),
                          child: DropdownButton<SongLanguageFilter>(
                            value: _languageFilter,
                            icon: Icon(Icons.arrow_drop_down, color: darkGray2),
                            underline: const SizedBox(),
                            isExpanded: true,
                            onChanged: _onFilterChanged,
                            items: const [
                              DropdownMenuItem(
                                value: SongLanguageFilter.all,
                                child: Text(
                                  'All Languages',
                                  style: TextStyle(fontSize: 13), // Reduced from 15 to 13
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongLanguageFilter.tagalog,
                                child: Text(
                                  'Tagalog Only',
                                  style: TextStyle(fontSize: 13), // Reduced from 15 to 13
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongLanguageFilter.english,
                                child: Text(
                                  'English Only',
                                  style: TextStyle(fontSize: 13), // Reduced from 15 to 13
                                ),
                              ),
                            ],
                            style: TextStyle(
                              color: black,
                              fontSize: 13, // Reduced from 15 to 13
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // Reduced from 16 to 12
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced from 16 to 12
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(16), // Reduced from 20 to 16
                            border: Border.all(color: lightGray2, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: black.withOpacity(0.1),
                                blurRadius: 6, // Reduced from 8 to 6
                                offset: const Offset(0, 3), // Reduced from 4 to 3
                              ),
                            ],
                          ),
                          child: DropdownButton<SongTypeFilter>(
                            value: _typeFilter,
                            icon: Icon(Icons.arrow_drop_down, color: darkGray2),
                            underline: const SizedBox(),
                            isExpanded: true,
                            onChanged: (newType) {
                              if (newType != null) setState(() => _typeFilter = newType);
                            },
                            items: const [
                              DropdownMenuItem(
                                value: SongTypeFilter.all,
                                child: Text(
                                  'All Songs',
                                  style: TextStyle(fontSize: 13), // Reduced from 15 to 13
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongTypeFilter.fast,
                                child: Text(
                                  'Fast Songs',
                                  style: TextStyle(fontSize: 13), // Reduced from 15 to 13
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongTypeFilter.slow,
                                child: Text(
                                  'Slow Songs',
                                  style: TextStyle(fontSize: 13), // Reduced from 15 to 13
                                ),
                              ),
                            ],
                            style: TextStyle(
                              color: black,
                              fontSize: 13, // Reduced from 15 to 13
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(24), // Reduced from 28 to 24
                      border: Border.all(
                        color: _isSearchFocused ? black : lightGray2,
                        width: _isSearchFocused ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSearchFocused
                              ? black.withOpacity(0.2)
                              : black.withOpacity(0.1),
                          blurRadius: _isSearchFocused ? 14 : 6, // Reduced from 16 to 14 and 8 to 6
                          offset: const Offset(0, 3), // Reduced from 4 to 3
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
                        style: TextStyle(
                          color: black,
                          fontSize: 14, // Reduced from 16 to 14
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search your favorite songs...',
                          hintStyle: TextStyle(
                            color: darkGray2.withOpacity(0.7),
                            fontSize: 14, // Reduced from 16 to 14
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                            child: Icon(
                              Icons.search,
                              color: _isSearchFocused ? black : darkGray2,
                              size: 20, // Reduced from 24 to 20
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(5), // Reduced from 6 to 5
                              decoration: BoxDecoration(
                                color: darkGray2,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.clear,
                                color: white,
                                size: 14, // Reduced from 16 to 14
                              ),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, // Reduced from 20 to 16
                            vertical: 16, // Reduced from 20 to 16
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
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: lightGray2, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: darkGray2,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedSongs.isEmpty
                            ? 'Select songs to delete'
                            : '${_selectedSongs.length} ${_selectedSongs.length == 1 ? 'song' : 'songs'} selected',
                        style: TextStyle(
                          color: black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedSongs.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [darkGray1, darkGray2],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => _showDeleteConfirmDialog(context, repo),
                          style: TextButton.styleFrom(
                            foregroundColor: white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lightGray2, width: 1),
                      ),
                      child: TextButton(
                        onPressed: _toggleSelectionMode,
                        style: TextButton.styleFrom(
                          foregroundColor: black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(darkGray2),
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Loading your songs...',
                            style: TextStyle(
                              color: darkGray2,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [darkGray1, darkGray2],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: black.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              color: black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: TextStyle(
                              color: darkGray2,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allSongs = snapshot.data ?? [];
                  final filteredSongs = filterSongs(
                    allSongs,
                    languageFilter: _languageFilter,
                    typeFilter:     _typeFilter,
                    searchQuery:    _searchQuery,
                  );

                  if (allSongs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [darkGray1, darkGray2],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: black.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.music_off,
                              color: white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No songs available',
                            style: TextStyle(
                              color: black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            auth.isAdmin
                                ? 'Use the menu to add your first song!'
                                : 'Check back later for new songs',
                            style: TextStyle(
                              color: darkGray2,
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [darkGray1, darkGray2],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: black.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.search_off,
                              color: white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No songs found',
                            style: TextStyle(
                              color: black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try different keywords for "$_searchQuery"',
                            style: TextStyle(
                              color: darkGray2,
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
                          margin: const EdgeInsets.fromLTRB(24, 12, 24, 12), // Reduced from 16 to 12
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Reduced from 24, 18 to 20, 14
                          decoration: BoxDecoration(
                            gradient: auth.isAdmin
                                ? LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [darkGray1, darkGray2],
                            )
                                : LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [white, lightGray2],
                            ),
                            borderRadius: BorderRadius.circular(20), // Reduced from 24 to 20
                            border: Border.all(
                              color: auth.isAdmin ? darkGray1 : lightGray2,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: black.withOpacity(0.1),
                                blurRadius: 10, // Reduced from 12 to 10
                                offset: const Offset(0, 3), // Reduced from 4 to 3
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                auth.isAdmin ? Icons.admin_panel_settings : Icons.library_music,
                                color: auth.isAdmin ? white : black,
                                size: 20, // Reduced from 24 to 20
                              ),
                              const SizedBox(width: 10), // Reduced from 12 to 10
                              Text(
                                auth.isAdmin
                                    ? 'Admin Mode Active'
                                    : _getStatusText(filteredSongs.length, allSongs.length),
                                style: TextStyle(
                                  color: auth.isAdmin ? white : black,
                                  fontSize: 14, // Reduced from 16 to 14
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Songs list
                      Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              bottom: 10, // Integrate the bottom padding here
                            ),
                            itemCount: filteredSongs.length,
                              itemBuilder: (context, index) {
                                final song = filteredSongs[index];
                                final isSelected = _selectedSongs.contains(song.id);

                                // Adjust the margin for the last item to include the bottom padding
                                EdgeInsets itemMargin = const EdgeInsets.only(bottom: 12); // Reduced from 16 to 12
                                if (index == filteredSongs.length - 1) {
                                  itemMargin = const EdgeInsets.only(bottom: 0); // No additional margin for the last item
                                }

                                return Container(
                                  margin: itemMargin,
                                  decoration: BoxDecoration(
                                    color: white,
                                    borderRadius: BorderRadius.circular(20), // Reduced from 24 to 20
                                    border: Border.all(
                                      color: isSelected ? black : lightGray2,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? black.withOpacity(0.2)
                                            : black.withOpacity(0.08),
                                        blurRadius: isSelected ? 16 : 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20), // Reduced from 24 to 20
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
                                        padding: const EdgeInsets.all(16), // Reduced from 24 to 16
                                        child: Row(
                                          children: [
                                            if (_isSelectionMode && auth.isAdmin)
                                              Container(
                                                width: 20, // Reduced from 24 to 20
                                                height: 20, // Reduced from 24 to 20
                                                decoration: BoxDecoration(
                                                  color: isSelected ? black : Colors.transparent,
                                                  border: Border.all(
                                                    color: isSelected ? black : darkGray2,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(6), // Reduced from 8 to 6
                                                ),
                                                child: isSelected
                                                    ? const Icon(
                                                  Icons.check,
                                                  color: white,
                                                  size: 14, // Reduced from 16 to 14
                                                )
                                                    : null,
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [darkGray1, darkGray2],
                                                  ),
                                                  borderRadius: BorderRadius.circular(16), // Reduced from 20 to 16
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: black.withOpacity(0.3),
                                                      blurRadius: 10, // Reduced from 12 to 10
                                                      offset: const Offset(0, 3), // Reduced from 4 to 3
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.music_note,
                                                  color: white,
                                                  size: 20, // Reduced from 24 to 20
                                                ),
                                              ),
                                            const SizedBox(width: 16), // Reduced from 20 to 16
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    song.title,
                                                    style: TextStyle(
                                                      color: black,
                                                      fontSize: 16, // Reduced from 18 to 16
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: -0.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4), // Reduced from 6 to 4
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10, // Reduced from 12 to 10
                                                          vertical: 4, // Reduced from 6 to 4
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: lightGray2,
                                                          borderRadius: BorderRadius.circular(14), // Reduced from 16 to 14
                                                          border: Border.all(
                                                            color: lightGray1,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          song.creator,
                                                          style: TextStyle(
                                                            color: black,
                                                            fontSize: 12, // Reduced from 13 to 12
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6), // Reduced from 8 to 6
                                                      if (song.language != null)
                                                        Flexible(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8, // Reduced from 10 to 8
                                                              vertical: 3, // Reduced from 4 to 3
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: darkGray2,
                                                              borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
                                                            ),
                                                            child: Text(
                                                              song.language!.toUpperCase(),
                                                              style: const TextStyle(
                                                                color: white,
                                                                fontSize: 10, // Reduced from 11 to 10
                                                                fontWeight: FontWeight.w700,
                                                                letterSpacing: 0.5,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      if (song.type != null)
                                                        Flexible(
                                                          child: Container(
                                                            margin: const EdgeInsets.only(left: 6), // Reduced from 8 to 6
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8, // Reduced from 10 to 8
                                                              vertical: 3, // Reduced from 4 to 3
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: black,
                                                              borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
                                                            ),
                                                            child: Text(
                                                              song.type!.toUpperCase(),
                                                              style: const TextStyle(
                                                                color: white,
                                                                fontSize: 10, // Reduced from 11 to 10
                                                                fontWeight: FontWeight.w700,
                                                                letterSpacing: 0.5,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!_isSelectionMode)
                                              Container(
                                                padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                                                decoration: BoxDecoration(
                                                  color: lightGray2,
                                                  borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: darkGray2,
                                                  size: 14, // Reduced from 16 to 14
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
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

  void _onFilterChanged(SongLanguageFilter? newFilter) {
    if (newFilter != null) {
      setState(() {
        _languageFilter = newFilter;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedSongs.clear();
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

  String _getStatusText(int filteredCount, int totalCount) {
    if (filteredCount == totalCount) {
      return 'Showing all $totalCount songs';
    } else {
      return 'Showing $filteredCount of $totalCount songs';
    }
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  color: white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from admin mode?',
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  auth.logout();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, SongRepository repo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete,
                  color: white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Songs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${_selectedSongs.length} ${_selectedSongs.length == 1 ? 'song' : 'songs'}? This action cannot be undone.',
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  for (String songId in _selectedSongs) {
                    await repo.deleteSong(songId);
                  }
                  _toggleSelectionMode();
                },
                style: TextButton.styleFrom(
                  foregroundColor: white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Song> filterSongs(
      List<Song> songs, {
        required SongLanguageFilter languageFilter,
        required SongTypeFilter typeFilter,
        required String searchQuery,
      }) {
    var filtered = songs;

    // 1) Language filter
    switch (languageFilter) {
      case SongLanguageFilter.tagalog:
        filtered = filtered
            .where((s) => s.language == 'tagalog')
            .toList();
        break;
      case SongLanguageFilter.english:
        filtered = filtered
            .where((s) => s.language == 'english')
            .toList();
        break;
      case SongLanguageFilter.all:
        break;
    }

    // 2) Type filter
    switch (typeFilter) {
      case SongTypeFilter.fast:
        filtered = filtered
            .where((s) => s.type == 'fast song' || s.type == 'fast')
            .toList();
        break;
      case SongTypeFilter.slow:
        filtered = filtered
            .where((s) => s.type == 'slow song' || s.type == 'slow')
            .toList();
        break;
      case SongTypeFilter.all:
        break;
    }

    // 3) Title search filter (case‑insensitive)
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered
          .where((s) => s.title.toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }
}