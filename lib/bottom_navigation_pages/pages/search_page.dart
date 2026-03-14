import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import 'now_playing_page.dart';
import '../../widgets/app_loading_widget.dart';
import '../../widgets/song_action_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Timer? _debounce;

  List<Map<String, dynamic>> allSongs = [];
  List<Map<String, dynamic>> filteredSongs = [];

  final TextEditingController _controller = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await Supabase.instance.client.from('songs').select('*');

      if (!mounted) return;

      setState(() {
        allSongs = List<Map<String, dynamic>>.from(response);

        filteredSongs = allSongs;

        isLoading = false;
      });
    } catch (e) {
      print("Error fetching songs: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void filterSongs(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final lowerQuery = query.toLowerCase();

      final results =
          allSongs.where((song) {
            final title = (song['title'] ?? '').toLowerCase();

            final artist = (song['artist'] ?? '').toLowerCase();

            return title.contains(lowerQuery) || artist.contains(lowerQuery);
          }).toList();

      setState(() => filteredSongs = results);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<SongPlayerProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Search",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),

              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                  ),

                  child: TextField(
                    controller: _controller,

                    onChanged: filterSongs,

                    style: const TextStyle(color: Colors.white),

                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.white70),

                      hintText: "What do you want to listen to?",

                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),

                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          isLoading
              ? const Expanded(child: AppLoadingWidget())
              : filteredSongs.isEmpty
              ? const Expanded(
                child: Center(
                  child: Text(
                    'No matching songs found',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
              : Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: filteredSongs.length,

                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];

                    return InkWell(
                      onTap: () {
                        /// Important for next/previous
                        playerProvider.setPlaylist(allSongs);

                        playerProvider.playSong(song);
                      },

                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),

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

                              onPressed: () => _showBottomDrawer(context, song),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  void _showBottomDrawer(BuildContext context, Map<String, dynamic> song) {
    showSongActionSheet(context: context, song: song, playlist: allSongs);
  }
}
