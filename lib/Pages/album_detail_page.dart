import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/album.dart';
import '../Models/songs.dart';
import '../Services/album_repository.dart';
import '../Services/song_repository.dart';
import '../transition.dart';
import 'song_detail_page.dart';

// Define color palette
class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color darkGray1 = Color(0xFF1F1F1F);
  static const Color darkGray2 = Color(0xFF242424);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray1 = Color(0xFFF2F2F2);
  static const Color lightGray2 = Color(0xFFE2E2E2);
}

class AlbumDetailPage extends StatefulWidget {
  final Album album;

  const AlbumDetailPage({super.key, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late List<String> _currentSongIds;

  @override
  void initState() {
    super.initState();
    _currentSongIds = List.from(widget.album.songIds);
  }

  Future<void> _removeSong(String songId) async {
    _currentSongIds.remove(songId);
    await context.read<AlbumRepository>().updateAlbumSongs(widget.album.id, _currentSongIds);
    setState(() {});
  }

  Future<void> _showAddSongsDialog(List<Song> allSongs) async {
    final available = allSongs.where((s) => !_currentSongIds.contains(s.id)).toList();
    final Map<String, bool> selected = {for (var s in available) s.id: false};
    String searchQuery = '';
    List<Song> filteredSongs = List.from(available);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateSearch(String query) {
            setDialogState(() {
              searchQuery = query.toLowerCase();
              filteredSongs = available.where((song) {
                final title = song.title.toLowerCase();
                final creator = song.creator.toLowerCase();
                return title.contains(searchQuery) || creator.contains(searchQuery);
              }).toList();
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add to Album',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: TextField(
                      onChanged: updateSearch,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search songs...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.black87, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredSongs.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filteredSongs.length} song${filteredSongs.length != 1 ? 's' : ''} available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredSongs.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            searchQuery.isEmpty ? Icons.music_note_outlined : Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isEmpty ? 'No songs available to add' : 'No songs match your search',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: selected[song.id] == true ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected[song.id] == true ? Colors.black : Colors.black12,
                            ),
                            boxShadow: selected[song.id] == true
                                ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                                : null,
                          ),
                          child: CheckboxListTile(
                            value: selected[song.id],
                            title: Text(
                              song.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: selected[song.id] == true ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              song.creator,
                              style: TextStyle(
                                color: selected[song.id] == true ? Colors.white70 : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                selected[song.id] = value!;
                              });
                            },
                            activeColor: Colors.white,
                            checkColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final toAdd = selected.entries.where((e) => e.value).map((e) => e.key);
                  if (toAdd.isNotEmpty) {
                    _currentSongIds.addAll(toAdd);
                    await context.read<AlbumRepository>().updateAlbumSongs(widget.album.id, _currentSongIds);
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Add ${selected.values.where((v) => v).length} Song${selected.values.where((v) => v).length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songRepo = context.watch<SongRepository>();

    return Scaffold(
      backgroundColor: AppColors.lightGray1, // Set the background color to lightGray1
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.album.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final allSongs = await songRepo.songsStream.first;
                      await _showAddSongsDialog(allSongs);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<Song>>(
                stream: songRepo.songsStream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allSongs = snap.data ?? [];
                  final inAlbum = allSongs.where((s) => _currentSongIds.contains(s.id)).toList();
                  if (inAlbum.isEmpty) {
                    return const Center(
                      child: Text('No songs here yet', style: TextStyle(color: Colors.black54)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: inAlbum.length,
                    itemBuilder: (_, i) {
                      final song = inAlbum[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                FadePageRoute(
                                  builder: (_) => SongDetailPage(song: song),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.black87,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                            letterSpacing: -0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.creator,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                            letterSpacing: -0.1,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.black87,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => _removeSong(song.id),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
