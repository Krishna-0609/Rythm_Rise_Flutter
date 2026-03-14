import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../provider/song_player_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_loading_widget.dart';
import '../../../widgets/song_action_sheet.dart';

class EnglishSong extends StatefulWidget {
  const EnglishSong({super.key});

  @override
  State<EnglishSong> createState() => _EnglishSongState();
}

class _EnglishSongState extends State<EnglishSong> {
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await supabase.from('english_song').select('*');
      if (!mounted) return;

      setState(() {
        songs = List<Map<String, dynamic>>.from(response);
        songs.sort(
          (a, b) =>
              a['title'].toLowerCase().compareTo(b['title'].toLowerCase()),
        );
        isLoading = false;
      });
    } catch (error) {
      if (mounted) setState(() => isLoading = false);
      print("🚨 Error fetching songs: $error");
    }
  }

  void _playSong(Map<String, dynamic> song) {
    final playerProvider = Provider.of<SongPlayerProvider>(
      context,
      listen: false,
    );

    if (playerProvider.currentSongId == song['id']) {
      playerProvider
          .togglePlayPause(); // Toggle play/pause if the same song is tapped
    } else {
      playerProvider.setPlaylist(songs);
      playerProvider.playSong(song); // Play the new song if different
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Top English Songs",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body:
          isLoading
              ? const AppLoadingWidget()
              : songs.isEmpty
              ? const Center(
                child: Text(
                  'No songs available',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title'] ?? "Unknown Title",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song['artist'] ?? "Unknown Artist",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          Builder(
                            builder:
                                (innerContext) => IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed:
                                      () => _showBottomDrawer(
                                        innerContext,
                                        song,
                                      ),
                                ),
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
