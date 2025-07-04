import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../Models/songs.dart';

class SongRepository extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _songs => _db.collection('songs');

  Stream<List<Song>> get songsStream {
    return _songs.orderBy('title').snapshots().map((snap) {
      return snap.docs.map((doc) => Song.fromFirestore(doc)).toList();
    });
  }

  Future<void> addSong(Song song) async {
    await _songs.add(song.toMap());
  }

  Future<void> updateSong(Song song) async {
    await _songs.doc(song.id).update(song.toMap());
  }

  Future<void> deleteSong(String id) async {
    await _songs.doc(id).delete();
  }
}
