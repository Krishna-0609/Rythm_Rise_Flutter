import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/custom_playlist_provider.dart';
import '../provider/song_player_provider.dart';
import '../theme/responsive_utils.dart';

Future<void> showSongActionSheet({
  required BuildContext context,
  required Map<String, dynamic> song,
  required List<Map<String, dynamic>> playlist,
  bool showRemoveFromFavorites = false,
  String? customPlaylistId,
  String? customPlaylistName,
}) {
  final provider = Provider.of<SongPlayerProvider>(context, listen: false);
  final customPlaylistProvider = Provider.of<CustomPlaylistProvider>(
    context,
    listen: false,
  );
  final isFavorite = provider.isFavorite(song['id'].toString());

  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.82),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (sheetContext) {
      final compact = ResponsiveUtils.isCompact(sheetContext);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song['album_art'] ?? '',
                    width: compact ? 54 : 60,
                    height: compact ? 54 : 60,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.music_note,
                          size: 50,
                          color: Colors.grey,
                        ),
                  ),
                ),
                SizedBox(width: compact ? 12 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'] ?? 'Unknown Title',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.responsiveFont(
                            sheetContext,
                            compact: 14,
                            regular: 15,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song['artist'] ?? 'Unknown Artist',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: ResponsiveUtils.responsiveFont(
                            sheetContext,
                            compact: 12,
                            regular: 13,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.white),
              title: const Text(
                'Play Music',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await provider.setPlaylist(playlist);
                await provider.playSong(song);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music, color: Colors.white),
              title: const Text(
                'Add to Queue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                provider.addToQueue(song);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
              title: const Text(
                'Add to Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                if (context.mounted) Navigator.pop(context);
                await _showPlaylistPicker(context: context, song: song);
              },
            ),
            if (customPlaylistId != null)
              ListTile(
                leading: const Icon(
                  Icons.playlist_remove_rounded,
                  color: Colors.redAccent,
                ),
                title: Text(
                  customPlaylistName == null || customPlaylistName.trim().isEmpty
                      ? 'Remove from Playlist'
                      : 'Remove from $customPlaylistName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  await customPlaylistProvider.removeSongFromPlaylist(
                    playlistId: customPlaylistId,
                    songId: song['id']?.toString() ?? '',
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ListTile(
              leading: Icon(
                showRemoveFromFavorites || isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color:
                    showRemoveFromFavorites || isFavorite
                        ? Colors.redAccent
                        : Colors.white,
              ),
              title: Text(
                showRemoveFromFavorites || isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                provider.toggleFavorite(song);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showPlaylistPicker({
  required BuildContext context,
  required Map<String, dynamic> song,
}) async {
  final playlistProvider = Provider.of<CustomPlaylistProvider>(
    context,
    listen: false,
  );

  final playlists = playlistProvider.playlists;

  if (playlists.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a custom playlist in Library first'),
        ),
      );
    }
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.black.withOpacity(0.88),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(sheetContext).viewPadding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to which playlist?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...playlists.map((playlist) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _PlaylistThumb(imageUrl: playlist.imageUrl),
                ),
                title: Text(
                  playlist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${playlist.songs.length} songs',
                  style: const TextStyle(color: Colors.white60),
                ),
                onTap: () async {
                  final added = await playlistProvider.addSongToPlaylist(
                    playlistId: playlist.id,
                    song: song,
                  );
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added
                              ? 'Added to ${playlist.name}'
                              : 'Song already exists in ${playlist.name}',
                        ),
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
      );
    },
  );
}

class _PlaylistThumb extends StatelessWidget {
  const _PlaylistThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 52,
        height: 52,
        color: Colors.white10,
        child: const Icon(Icons.queue_music_rounded, color: Colors.white70),
      );
    }

    if (!_looksLikeNetworkImage(imageUrl)) {
      return Image.file(
        File(imageUrl),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 52,
            height: 52,
            color: Colors.white10,
            child: const Icon(Icons.queue_music_rounded, color: Colors.white70),
          );
        },
      );
    }

    return Image.network(
      imageUrl,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 52,
          height: 52,
          color: Colors.white10,
          child: const Icon(Icons.queue_music_rounded, color: Colors.white70),
        );
      },
    );
  }
}

bool _looksLikeNetworkImage(String value) {
  final trimmed = value.trim().toLowerCase();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}





