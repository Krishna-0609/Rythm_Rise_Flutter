import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/song_player_provider.dart';

Future<void> showSongActionSheet({
  required BuildContext context,
  required Map<String, dynamic> song,
  required List<Map<String, dynamic>> playlist,
  bool showRemoveFromFavorites = false,
}) {
  final provider = Provider.of<SongPlayerProvider>(context, listen: false);
  final isFavorite = provider.isFavorite(song['id'].toString());

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.82),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song['album_art'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.music_note,
                          size: 50,
                          color: Colors.grey,
                        ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song['artist'] ?? 'Unknown Artist',
                        style: const TextStyle(color: Colors.grey),
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
