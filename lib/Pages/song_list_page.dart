import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/song_repository.dart';
import '../services/auth_service.dart';
import '../Models/songs.dart';
import 'song_detail_page.dart';
import 'add_song_page.dart';
import 'pin_page.dart';

class SongListPage extends StatelessWidget {
  const SongListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SongRepository>();
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chord Sheets'),
        actions: [
          IconButton(
            icon: Icon(auth.isAdmin ? Icons.lock_open : Icons.lock),
            onPressed: () {
              if (auth.isAdmin) {
                auth.logout();
              } else {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PinPage()));
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Song>>(
        stream: repo.songsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final songs = snapshot.data!;
          if (songs.isEmpty) {
            return const Center(child: Text("No songs available."));
          }
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                title: Text(song.title),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SongDetailPage(song: song),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSongPage()),
        ),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
