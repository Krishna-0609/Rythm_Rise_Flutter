import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/song_fetcher.dart';
import '../../../provider/song_player_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_utils.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/song_action_sheet.dart';

class ArtistPlaylistPage extends StatefulWidget {
  const ArtistPlaylistPage({
    super.key,
    required this.title,
    required this.artistKeywords,
  });

  final String title;
  final List<String> artistKeywords;

  @override
  State<ArtistPlaylistPage> createState() => _ArtistPlaylistPageState();
}

class _ArtistPlaylistPageState extends State<ArtistPlaylistPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await fetchAllSongs(supabase, 'songs');
      final filteredSongs =
          List<Map<String, dynamic>>.from(response).where(_matchesArtist).toList();

      filteredSongs.sort(
        (a, b) => (a['title'] ?? '').toString().toLowerCase().compareTo(
          (b['title'] ?? '').toString().toLowerCase(),
        ),
      );

      if (!mounted) return;

      setState(() {
        songs = filteredSongs;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Error fetching artist playlist for ${widget.title}: $error');
    }
  }

  bool _matchesArtist(Map<String, dynamic> song) {
    final artist = _normalizeArtist(song['artist']?.toString() ?? '');

    if (artist.isEmpty) {
      return false;
    }

    return widget.artistKeywords.any(
      (keyword) => artist.contains(_normalizeArtist(keyword)),
    );
  }

  String _normalizeArtist(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _playSong(Map<String, dynamic> song) {
    final playerProvider = Provider.of<SongPlayerProvider>(
      context,
      listen: false,
    );

    if (playerProvider.currentSongId == song['id']) {
      playerProvider.togglePlayPause();
    } else {
      playerProvider.setPlaylist(songs);
      playerProvider.playSong(song);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final compact = ResponsiveUtils.isCompact(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body:
          isLoading
              ? const AppLoadingWidget()
              : songs.isEmpty
              ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    'No songs found for ${widget.title}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 14 : 20,
                  horizontalPadding,
                  16,
                ),
                itemCount: songs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final song = songs[index];

                  return InkWell(
                    splashColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _playSong(song),
                    child: SizedBox(
                      height: 70,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              song["album_art"] ?? "",
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
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song['artist'] ?? "Unknown Artist",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                    fontSize: ResponsiveUtils.responsiveFont(
                                      context,
                                      compact: 12,
                                      regular: 13,
                                      tablet: 14,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                    ),
                  );
                },
              ),
    );
  }

  void _showBottomDrawer(BuildContext context, Map<String, dynamic> song) {
    showSongActionSheet(context: context, song: song, playlist: songs);
  }
}
