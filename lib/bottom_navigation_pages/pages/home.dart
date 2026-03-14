import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_loading_widget.dart';
import '../../widgets/song_action_sheet.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
      final response = await supabase.from('songs').select('*');

      if (!mounted) return;

      songs = List<Map<String, dynamic>>.from(response);

      songs.sort(
        (a, b) => (a['title'] ?? '').toLowerCase().compareTo(
          (b['title'] ?? '').toLowerCase(),
        ),
      );

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => isLoading = false);
      }

      debugPrint("Error fetching songs: $error");
    }
  }

  void _playSong(Map<String, dynamic> song) {
    final provider = Provider.of<SongPlayerProvider>(context, listen: false);

    provider.setPlaylist(songs);
    provider.playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          "All Songs",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          Expanded(
            child:
                isLoading
                    ? _loadingWidget()
                    : songs.isEmpty
                    ? const Center(
                      child: Text(
                        "No songs available",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),

                      itemCount: songs.length,

                      separatorBuilder: (_, __) => const SizedBox(height: 12),

                      itemBuilder: (context, index) {
                        final song = songs[index];

                        return InkWell(
                          onTap: () => _playSong(song),

                          borderRadius: BorderRadius.circular(12),

                          child: Row(
                            children: [
                              /// Album art
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

                              /// Title + artist
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      song['title'] ?? "Unknown Title",

                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),

                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    Text(
                                      song['artist'] ?? "Unknown Artist",

                                      style: const TextStyle(
                                        color: Colors.white70,
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

                                onPressed:
                                    () => _showBottomDrawer(context, song),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _loadingWidget() {
    return const AppLoadingWidget();
  }

  void _showBottomDrawer(BuildContext context, Map<String, dynamic> song) {
    showSongActionSheet(context: context, song: song, playlist: songs);
  }
}
