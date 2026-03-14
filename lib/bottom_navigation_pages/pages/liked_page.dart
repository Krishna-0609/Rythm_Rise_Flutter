import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import 'now_playing_page.dart';
import '../../widgets/song_action_sheet.dart';

class LikedPage extends StatelessWidget {
  const LikedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Liked Songs",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Consumer<SongPlayerProvider>(
        builder: (context, playerProvider, _) {
          final favoriteSongs = playerProvider.favoriteSongs;

          if (favoriteSongs.isEmpty) {
            return const Center(
              child: Text(
                "No favorite songs added.",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: favoriteSongs.length,

            itemBuilder: (context, index) {
              final song = favoriteSongs[index];

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song['album_art'] ?? "",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                            const Icon(Icons.music_note, color: Colors.grey),
                  ),
                ),

                title: Text(
                  song['title'] ?? "Unknown Title",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  song['artist'] ?? "Unknown Artist",
                  style: const TextStyle(color: Colors.white70),
                ),

                trailing: IconButton(
                  icon: const Icon(
                    Icons.more_vert_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _showBottomDrawer(context, song),
                ),

                onTap: () {
                  /// important for next/previous sync
                  playerProvider.setPlaylist(favoriteSongs);

                  playerProvider.playSong(song);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showBottomDrawer(BuildContext context, Map<String, dynamic> song) {
    final provider = Provider.of<SongPlayerProvider>(context, listen: false);
    showSongActionSheet(
      context: context,
      song: song,
      playlist: provider.favoriteSongs,
      showRemoveFromFavorites: true,
    );
  }
}
