import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/song_fetcher.dart';
import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_utils.dart';
import '../../widgets/app_loading_widget.dart';
import '../../widgets/song_action_sheet.dart';
import 'song_page/artist_playlist_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final SupabaseClient supabase = Supabase.instance.client;
  static const List<_ArtistPlaylistPreview> _artistPlaylists = [
    _ArtistPlaylistPreview(
      title: 'Anirudh Hits',
      imageUrl:
          'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774342003/lplsissuxry24ky5r0j4.jpg',
      artistKeywords: ['anirudh'],
    ),
    _ArtistPlaylistPreview(
      title: 'Hiphop Tamizha',
      imageUrl:
          'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774343456/jka8fwhjt6dw8jp7mcwk.jpg',
      artistKeywords: [
        'hiphop tamizha',
        'hip hop tamizha',
        'hiphop tamila',
        'hip hop tamila',
      ],
    ),
    _ArtistPlaylistPreview(
      title: 'Sid Sriram',
      imageUrl:
          'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774343721/zqcqfqb9jvqqulwimx18.jpg',
      artistKeywords: ['sid sriram'],
    ),
    _ArtistPlaylistPreview(
      title: 'Ilaiyaraaja Hits',
      imageUrl:
          'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774432318/kmf6hmqlup22luzzkxnv.jpg',
      artistKeywords: ['Ilaiyaraaja'],
    ),
    _ArtistPlaylistPreview(
      title: 'S.P.Balasubrahmanyam',
      imageUrl:
          'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774442495/jl91hbadje1ozprnajml.jpg',
      artistKeywords: ['S.P.Balasubrahmanyam', 'S.P.B'],
    ),
    _ArtistPlaylistPreview(
      title: 'A.R.Rahman Hits',
      imageUrl:
      'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774507273/jk5jourft28wqni7vkvl.jpg',
      artistKeywords: ['A.R.Rahman'],
    ),
    _ArtistPlaylistPreview(
      title: 'G.V.Prakash Hits',
      imageUrl:
      'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774612639/j23svngsecytau56hm5n.jpg',
      artistKeywords: ['G.V.Pragash','G. V. Prakash Kumar','G.V'],
    ),
    _ArtistPlaylistPreview(
      title: 'Yuvan Shankar Raja',
      imageUrl:
      'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774614308/optgcdeqkgb07i1sxdzb.jpg',
      artistKeywords: ['Yuvan Shankar Raja','Yuvan','U1'],
    ),
    _ArtistPlaylistPreview(
      title: 'Shreya Ghoshal',
      imageUrl:
      'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774614922/wxjro9ladd6jk26yxvkm.jpg',
      artistKeywords: ['Shreya Ghoshal'],
    ),
    _ArtistPlaylistPreview(
      title: 'Mano Hits',
      imageUrl:
      'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774615253/qqshrwcolzn9okqpcifr.jpg',
      artistKeywords: ['Mano'],
    ),
    _ArtistPlaylistPreview(
      title: 'S. Janaki',
      imageUrl:
      'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774616117/erzjy6rvtfj7nciuyc0z.jpg',
      artistKeywords: ['S. Janaki','Janaki'],
    ),
    _ArtistPlaylistPreview(
      title: 'Harris Jayaraj',
      imageUrl:
      'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774701967/fxd7abvr6onzer1hwtp1.jpg',
      artistKeywords: ['Harris Jayaraj'],
    ),
  ];

  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> recentlyPlayed = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await fetchAllSongs(supabase, 'songs');
      final fetchedSongs = List<Map<String, dynamic>>.from(response)
        ..sort(
          (a, b) => (a['title'] ?? '').toLowerCase().compareTo(
            (b['title'] ?? '').toLowerCase(),
          ),
        );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('library_song_count', fetchedSongs.length);

      final recentRaw = prefs.getStringList('recently_played') ?? <String>[];
      final recentSongs = <Map<String, dynamic>>[];

      for (final item in recentRaw) {
        try {
          recentSongs.add(Map<String, dynamic>.from(jsonDecode(item) as Map));
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        songs = fetchedSongs;
        recentlyPlayed = recentSongs;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Error fetching songs: $error');
    }
  }

  void _playSong(Map<String, dynamic> song) {
    final provider = Provider.of<SongPlayerProvider>(context, listen: false);
    provider.setPlaylist(songs);
    provider.playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final compact = ResponsiveUtils.isCompact(context);
    final sectionGap = ResponsiveUtils.contentGap(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: isLoading
            ? const AppLoadingWidget()
            : RefreshIndicator(
                onRefresh: fetchSongs,
                color: AppColors.iconcolor2,
                backgroundColor: AppColors.secondary,
                child: Consumer<SongPlayerProvider>(
                  builder: (context, player, _) {
                    return ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 14 : 18,
                        horizontalPadding,
                        28,
                      ),
                      children: [
                        _buildTopBar(context),
                        SizedBox(height: sectionGap),
                        _buildHeroCard(context, player),
                        SizedBox(height: sectionGap),
                        _buildShortcutRow(context, player),
                        SizedBox(height: sectionGap + 2),
                        if (recentlyPlayed.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'Recently played',
                            subtitle: 'Jump back into your latest vibe',
                          ),
                          const SizedBox(height: 14),
                          _SongCarousel(
                            songs: recentlyPlayed.take(6).toList(),
                            onSongTap: _playSong,
                            onSongMore: _showBottomDrawer,
                          ),
                          SizedBox(height: sectionGap + 4),
                        ],
                        _SectionTitle(
                          title: 'Artist playlists',
                          subtitle: 'Your library artists, now right on Home',
                        ),
                        const SizedBox(height: 14),
                        _ArtistPlaylistCarousel(
                          playlists: _artistPlaylists,
                        ),
                        SizedBox(height: sectionGap + 4),
                        _SectionTitle(
                          title: 'Browse all songs',
                          subtitle: 'Your full collection in one smooth list',
                        ),
                        const SizedBox(height: 14),
                        if (songs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text(
                                'No songs available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          )
                        else
                          ...songs.map(
                            (song) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SongListTile(
                                song: song,
                                onTap: () => _playSong(song),
                                onMore: () => _showBottomDrawer(context, song),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.responsiveFont(
                    context,
                    compact: 26,
                    regular: 30,
                    tablet: 34,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Discover, replay, and keep the music flowing.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, SongPlayerProvider player) {
    final currentTitle = player.currentSongTitle;
    final currentArtist = player.currentArtist;

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.isCompact(context) ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xffE15B8F),
            Color(0xffA64DB3),
            Color(0xff232B4D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Rythm Home Mix',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            currentTitle == null ? 'Start with something you love' : currentTitle,
            style: TextStyle(
              color: Colors.white,
              height: 1.1,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.responsiveFont(
                context,
                compact: 24,
                regular: 29,
                tablet: 34,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentArtist == null
                ? 'A more immersive home screen inspired by Spotify, but still shaped around your own library.'
                : 'Currently playing by $currentArtist. Pick up where you left off or jump into a fresh mix.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: songs.isEmpty
                      ? null
                      : () => _playSong(
                            currentTitle == null ? songs.first : songs.firstWhere(
                                  (song) =>
                                      song['id'].toString() ==
                                      player.currentSongId?.toString(),
                                  orElse: () => songs.first,
                                ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(
                    currentTitle == null
                        ? Icons.play_arrow_rounded
                        : Icons.headphones_rounded,
                  ),
                  label: Text(currentTitle == null ? 'Play something' : 'Resume'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: songs.isEmpty ? null : fetchSongs,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Refresh mix'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(BuildContext context, SongPlayerProvider player) {
    final items = [
      _ShortcutData(
        icon: Icons.favorite_rounded,
        label: 'Liked Songs',
        value: '${player.favoriteSongs.length}',
        accent: AppColors.iconcolor2,
      ),
      _ShortcutData(
        icon: Icons.queue_music_rounded,
        label: 'Queue',
        value: '${player.queuedSongs.length}',
        accent: AppColors.iconcolor1,
      ),
      _ShortcutData(
        icon: Icons.history_rounded,
        label: 'Recents',
        value: '${recentlyPlayed.length}',
        accent: const Color(0xff76D7EA),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileWidth = width < 420 ? (width - 12) / 2 : (width - 24) / 3;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _ShortcutTile(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _showBottomDrawer(BuildContext context, Map<String, dynamic> song) {
    showSongActionSheet(context: context, song: song, playlist: songs);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.responsiveFont(
              context,
              compact: 18,
              regular: 20,
              tablet: 22,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SongCarousel extends StatelessWidget {
  const _SongCarousel({
    required this.songs,
    required this.onSongTap,
    required this.onSongMore,
  });

  final List<Map<String, dynamic>> songs;
  final ValueChanged<Map<String, dynamic>> onSongTap;
  final void Function(BuildContext, Map<String, dynamic>) onSongMore;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveUtils.isCompact(context);

    return SizedBox(
      height: compact ? 208 : 226,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = songs[index];

          return InkWell(
            onTap: () => onSongTap(song),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: compact ? 150 : 166,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        song['album_art'] ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: Colors.white60,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    song['title'] ?? 'Unknown Title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          song['artist'] ?? 'Unknown Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                      InkWell(
                        onTap: () => onSongMore(context, song),
                        borderRadius: BorderRadius.circular(99),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArtistPlaylistCarousel extends StatelessWidget {
  const _ArtistPlaylistCarousel({required this.playlists});

  final List<_ArtistPlaylistPreview> playlists;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveUtils.isCompact(context);

    return SizedBox(
      height: compact ? 208 : 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistPlaylistPage(
                    title: playlist.title,
                    artistKeywords: playlist.artistKeywords,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: compact ? 156 : 176,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        playlist.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(
                              Icons.library_music_rounded,
                              color: Colors.white60,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    playlist.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SongListTile extends StatelessWidget {
  const _SongListTile({
    required this.song,
    required this.onTap,
    required this.onMore,
  });

  final Map<String, dynamic> song;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveUtils.isCompact(context);

    return InkWell(
      splashColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        height: compact ? 68 : 72,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                song['album_art'] ?? '',
                width: compact ? 54 : 60,
                height: compact ? 54 : 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: compact ? 54 : 60,
                  height: compact ? 54 : 60,
                  color: Colors.white10,
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white60,
                  ),
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
                    song['title'] ?? 'Unknown Title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song['artist'] ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(
                Icons.more_vert_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistPlaylistPreview {
  const _ArtistPlaylistPreview({
    required this.title,
    required this.imageUrl,
    required this.artistKeywords,
  });

  final String title;
  final String imageUrl;
  final List<String> artistKeywords;
}

class _ShortcutData {
  const _ShortcutData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.data});

  final _ShortcutData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: data.accent.withOpacity(0.18),
            child: Icon(data.icon, color: data.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
