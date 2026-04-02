import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomPlaylist {
  const CustomPlaylist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.songs,
  });

  final String id;
  final String name;
  final String imageUrl;
  final List<Map<String, dynamic>> songs;

  CustomPlaylist copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<Map<String, dynamic>>? songs,
  }) {
    return CustomPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'songs': songs,
    };
  }

  factory CustomPlaylist.fromMap(Map<String, dynamic> map) {
    return CustomPlaylist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'My Playlist',
      imageUrl: map['imageUrl']?.toString() ?? '',
      songs: List<Map<String, dynamic>>.from(map['songs'] ?? const []),
    );
  }
}

class CustomPlaylistProvider extends ChangeNotifier {
  CustomPlaylistProvider() {
    loadPlaylists();
  }

  static const String _storageKey = 'custom_playlists';

  List<CustomPlaylist> _playlists = [];

  List<CustomPlaylist> get playlists => List.unmodifiable(_playlists);

  Future<void> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _playlists = [];
      notifyListeners();
      return;
    }

    final decoded = List<Map<String, dynamic>>.from(
      jsonDecode(raw) as List,
    );
    _playlists = decoded.map(CustomPlaylist.fromMap).toList();
    notifyListeners();
  }

  Future<void> createPlaylist({
    required String name,
    required String imageUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final playlist = CustomPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      imageUrl: imageUrl.trim(),
      songs: const [],
    );

    _playlists = [playlist, ..._playlists];
    await _save();
  }

  Future<bool> addSongToPlaylist({
    required String playlistId,
    required Map<String, dynamic> song,
  }) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1) return false;

    final playlist = _playlists[index];
    final songId = song['id']?.toString();
    final alreadyExists = playlist.songs.any(
      (item) => item['id']?.toString() == songId,
    );

    if (alreadyExists) {
      return false;
    }

    final updatedSongs = [...playlist.songs, Map<String, dynamic>.from(song)];
    _playlists[index] = playlist.copyWith(songs: updatedSongs);
    await _save();
    return true;
  }

  Future<void> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    final updatedSongs = playlist.songs
        .where((song) => song['id']?.toString() != songId)
        .toList();

    _playlists[index] = playlist.copyWith(songs: updatedSongs);
    await _save();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_playlists.map((playlist) => playlist.toMap()).toList()),
    );
    notifyListeners();
  }
}
