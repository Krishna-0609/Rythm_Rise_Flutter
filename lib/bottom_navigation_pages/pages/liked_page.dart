import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_utils.dart';
import 'now_playing_page.dart';
import '../../widgets/song_action_sheet.dart';

class LikedPage extends StatelessWidget {
  const LikedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final compact = ResponsiveUtils.isCompact(context);
    final sectionGap = ResponsiveUtils.contentGap(context);
    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Liked Songs",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.responsiveFont(
                  context,
                  compact: 22,
                  regular: 24,
                  tablet: 26,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your favorite tracks in one place',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),

      body: Consumer<SongPlayerProvider>(
        builder: (context, playerProvider, _) {
          final favoriteSongs = playerProvider.favoriteSongs;

          if (favoriteSongs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No favorite songs added.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              SizedBox(height: compact ? 12 : 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.iconcolor2.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${favoriteSongs.length} liked songs saved',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sectionGap),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: compact ? 8 : 12,
                  ),
                  itemCount: favoriteSongs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final song = favoriteSongs[index];

                    return InkWell(
                      onTap: () {
                        playerProvider.setPlaylist(favoriteSongs);
                        playerProvider.playSong(song);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              song['album_art'] ?? "",
                              width: compact ? 54 : 60,
                              height: compact ? 54 : 60,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: compact ? 54 : 60,
                                    height: compact ? 54 : 60,
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                          SizedBox(width: compact ? 12 : 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title'] ?? "Unknown Title",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveUtils.responsiveFont(
                                      context,
                                      compact: 14,
                                      regular: 15,
                                      tablet: 16,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song['artist'] ?? "Unknown Artist",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: ResponsiveUtils.responsiveFont(
                                      context,
                                      compact: 12,
                                      regular: 13,
                                      tablet: 14,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () => _showBottomDrawer(context, song),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
