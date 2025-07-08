import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/album.dart';

class AlbumRepository {
  final _col = FirebaseFirestore.instance.collection('albums');

  Stream<List<Album>> get albumsStream => _col.snapshots().map((snap) {
    return snap.docs.map((d) => Album.fromMap(d.id, d.data())).toList();
  });

  // Get all albums as a Future (for the auto-generation feature)
  Future<List<Album>> getAllAlbums() async {
    try {
      final QuerySnapshot snapshot = await _col.get();
      return snapshot.docs.map((doc) => Album.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting all albums: $e');
      return [];
    }
  }

  // Force refresh albums from server (bypasses cache)
  Future<List<Album>> refreshAlbums() async {
    try {
      final QuerySnapshot snapshot = await _col.get(const GetOptions(source: Source.server));
      return snapshot.docs.map((doc) => Album.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error refreshing albums from server: $e');
      // Fallback to cache if server fetch fails
      return await getAllAlbums();
    }
  }

  // Create a new album with songs
  Future<void> addAlbumWithSongs(String name, List<String> songIds) async {
    try {
      await _col.add({
        'name': name,
        'songIds': songIds,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding album with songs: $e');
      throw e;
    }
  }

  // Add songs to an existing album
  Future<void> addSongsToAlbum(String albumId, List<String> newSongIds) async {
    try {
      // Get current album data
      final DocumentSnapshot doc = await _col.doc(albumId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<String> currentSongIds = List<String>.from(data['songIds'] ?? []);

        // Add new songs (avoid duplicates)
        final updatedSongIds = [...currentSongIds];
        for (final songId in newSongIds) {
          if (!updatedSongIds.contains(songId)) {
            updatedSongIds.add(songId);
          }
        }

        // Update the album with new song list
        await _col.doc(albumId).update({
          'songIds': updatedSongIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding songs to album: $e');
      throw e;
    }
  }

  // Original methods (kept unchanged)
  Future<void> addAlbum(String name) {
    return _col.add({
      'name': name,
      'songIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAlbum(String id) {
    return _col.doc(id).delete();
  }

  Future<void> updateAlbumSongs(String id, List<String> songIds) {
    return _col.doc(id).update({
      'songIds': songIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Helper method to get a specific album
  Future<Album?> getAlbum(String id) async {
    try {
      final DocumentSnapshot doc = await _col.doc(id).get();
      if (doc.exists) {
        return Album.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting album: $e');
      return null;
    }
  }

  // Helper method to check if an album with a specific name exists
  Future<Album?> getAlbumByName(String name) async {
    try {
      final QuerySnapshot snapshot = await _col
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Album.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting album by name: $e');
      return null;
    }
  }

  // Enhanced method to check if album exists by name (case-insensitive)
  Future<Album?> getAlbumByNameCaseInsensitive(String name) async {
    try {
      // First try exact match (more efficient)
      final exactMatch = await getAlbumByName(name);
      if (exactMatch != null) return exactMatch;

      // If no exact match, get all albums and check case-insensitively
      final allAlbums = await getAllAlbums();
      final normalizedName = name.toLowerCase().trim();

      for (final album in allAlbums) {
        if (album.name.toLowerCase().trim() == normalizedName) {
          return album;
        }
      }

      return null;
    } catch (e) {
      print('Error getting album by name (case-insensitive): $e');
      return null;
    }
  }

  // Check if album exists by name (returns boolean)
  Future<bool> albumExistsByName(String name) async {
    final album = await getAlbumByNameCaseInsensitive(name);
    return album != null;
  }

  // Batch operation to check multiple album names at once
  Future<Map<String, Album?>> getAlbumsByNames(List<String> names) async {
    try {
      final result = <String, Album?>{};
      final allAlbums = await getAllAlbums();

      for (final name in names) {
        final normalizedName = name.toLowerCase().trim();
        result[name] = allAlbums.firstWhere(
              (album) => album.name.toLowerCase().trim() == normalizedName,
          orElse: () => Album(id: '', name: '', songIds: []),
        );

        // If album has empty ID, it means it wasn't found
        if (result[name]!.id.isEmpty) {
          result[name] = null;
        }
      }

      return result;
    } catch (e) {
      print('Error getting albums by names: $e');
      return {};
    }
  }
}