import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_utils.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  double? _dragValue;
  late final AnimationController _visualizerController;

  @override
  void initState() {
    super.initState();
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _visualizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Consumer<SongPlayerProvider>(
        builder: (context, player, _) {
          final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
          final sectionGap = ResponsiveUtils.contentGap(context);
          final artworkSize = ResponsiveUtils.playerArtworkSize(context);
          final lyricsHeight =
              (MediaQuery.sizeOf(context).height * 0.22).clamp(140.0, 240.0);
          final position = player.position;
          final duration = player.duration;
          final max = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
          final liveValue = position.inMilliseconds.clamp(0, max).toDouble();
          final sliderValue =
              (_dragValue ?? liveValue).clamp(0.0, max.toDouble()).toDouble();
          final isFavorite =
              player.currentSongId != null &&
              player.isFavorite(player.currentSongId!);

          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  player.currentAlbumArt ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(color: AppColors.primary);
                  },
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    color: Colors.black.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.14),
                        const Color(0xff111523).withOpacity(0.58),
                        const Color(0xff0E1220).withOpacity(0.82),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        20,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _GlassIconButton(
                                  icon: Icons.keyboard_arrow_down_rounded,
                                  onTap: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: const Text(
                                        'NOW PLAYING',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Rythm',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                _GlassIconButton(
                                  icon:
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                  onTap: () {
                                    final currentSong = player.playlist.firstWhere(
                                      (song) =>
                                          song['id'].toString() ==
                                          player.currentSongId,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    if (currentSong.isNotEmpty) {
                                      player.toggleFavorite(currentSong);
                                    }
                                  },
                                  active: isFavorite,
                                ),
                              ],
                            ),
                            SizedBox(height: sectionGap + 4),
                            Container(
                              height: artworkSize,
                              width: artworkSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.isCompact(context) ? 28 : 34,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    player.currentAlbumArt ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        color: Colors.white.withOpacity(0.06),
                                        child: const Icon(
                                          Icons.music_note_rounded,
                                          color: Colors.white38,
                                          size: 90,
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.08),
                                            Colors.black.withOpacity(0.32),
                                          ],
                                          stops: const [0.0, 0.60, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                ResponsiveUtils.isCompact(context) ? 18 : 22,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.10),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.16),
                                    blurRadius: 24,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.iconcolor2.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.iconcolor2.withOpacity(0.22),
                                      ),
                                    ),
                                    child: Text(
                                      player.isPlaying ? 'Live Session' : 'Paused',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    player.currentSongTitle ?? 'Unknown Title',
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: ResponsiveUtils.responsiveFont(
                                        context,
                                        compact: 22,
                                        regular: 28,
                                        tablet: 32,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    player.currentArtist ?? 'Unknown Artist',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: ResponsiveUtils.responsiveFont(
                                        context,
                                        compact: 14,
                                        regular: 16,
                                        tablet: 18,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _TrackAccentLine(
                                    controller: _visualizerController,
                                    isPlaying: player.isPlaying,
                                  ),
                                  const SizedBox(height: 20),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 9,
                                      ),
                                      overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 18,
                                      ),
                                      thumbColor: Colors.white,
                                      activeTrackColor: AppColors.iconcolor2,
                                      inactiveTrackColor: Colors.white24,
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: max.toDouble(),
                                      value: sliderValue,
                                      onChanged: (value) {
                                        setState(() {
                                          _dragValue = value;
                                        });
                                      },
                                      onChangeEnd: (value) async {
                                        setState(() {
                                          _dragValue = null;
                                        });
                                        await player.seek(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                      },
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(
                                          Duration(
                                            milliseconds: sliderValue.toInt(),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: sectionGap),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          player.isPlaying
                                              ? Icons.graphic_eq_rounded
                                              : Icons.multitrack_audio_rounded,
                                          size: 16,
                                          color: AppColors.iconcolor1,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          player.isPlaying
                                              ? 'Feel the groove'
                                              : 'Tap play to start the vibe',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: sectionGap),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _ControlIconButton(
                                        icon:
                                            player.isShuffle
                                                ? Icons.shuffle_on_rounded
                                                : Icons.shuffle_rounded,
                                        active: player.isShuffle,
                                        onTap: player.toggleShuffle,
                                      ),
                                      _ControlIconButton(
                                        icon: Icons.skip_previous_rounded,
                                        size: ResponsiveUtils.isCompact(context)
                                            ? 30
                                            : 34,
                                        onTap: player.playPrevious,
                                      ),
                                      _PrimaryPlayButton(
                                        isPlaying: player.isPlaying,
                                        onTap: player.togglePlayPause,
                                      ),
                                      _ControlIconButton(
                                        icon: Icons.skip_next_rounded,
                                        size: ResponsiveUtils.isCompact(context)
                                            ? 30
                                            : 34,
                                        onTap: player.playNext,
                                      ),
                                      _ControlIconButton(
                                        icon:
                                            player.isRepeat
                                                ? Icons.repeat_one_rounded
                                                : Icons.repeat_rounded,
                                        active: player.isRepeat,
                                        onTap: player.toggleRepeat,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            _UpNextCard(player: player),
                            SizedBox(height: sectionGap),
                            SizedBox(
                              width: double.infinity,
                              height: lyricsHeight,
                              child:
                                  player.currentLyrics != null &&
                                          player.currentLyrics!.isNotEmpty
                                      ? Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(26),
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Text(
                                            player.currentLyrics!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  ResponsiveUtils.responsiveFont(
                                                    context,
                                                    compact: 14,
                                                    regular: 16,
                                                    tablet: 17,
                                                  ),
                                              fontWeight: FontWeight.bold,
                                              height: 1.75,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                      : Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(26),
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'No Lyrics Available',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                            ),
                          ],
                        ),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: ResponsiveUtils.isCompact(context) ? 40 : 44,
        width: ResponsiveUtils.isCompact(context) ? 40 : 44,
        decoration: BoxDecoration(
          color:
              active
                  ? AppColors.iconcolor2.withOpacity(0.9)
                  : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: ResponsiveUtils.isCompact(context) ? 22 : 24,
        ),
      ),
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.size = 28,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: size,
        color: active ? AppColors.iconcolor2 : Colors.white,
      ),
    );
  }
}

class _PrimaryPlayButton extends StatelessWidget {
  const _PrimaryPlayButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: ResponsiveUtils.isCompact(context) ? 68 : 76,
        width: ResponsiveUtils.isCompact(context) ? 68 : 76,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.iconcolor2, AppColors.iconcolor1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: ResponsiveUtils.isCompact(context) ? 36 : 42,
        ),
      ),
    );
  }
}

class _TrackAccentLine extends StatelessWidget {
  const _TrackAccentLine({
    required this.controller,
    required this.isPlaying,
  });

  final AnimationController controller;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final shift = isPlaying ? controller.value : 0.18;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + (shift * 2), 0),
                  end: Alignment(1 + (shift * 2), 0),
                  colors: [
                    AppColors.iconcolor2.withOpacity(0.32),
                    AppColors.iconcolor2,
                    AppColors.iconcolor1,
                    Colors.white.withOpacity(0.92),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.player});

  final SongPlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final upcomingSongs = player.upcomingSongs.take(4).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.isCompact(context) ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.iconcolor2.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Up Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'What will play after this track',
                      style: TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${player.upcomingSongs.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcomingSongs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'No songs in the up next list right now. Add songs to queue or start a playlist to keep the music going.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
            )
          else
            ...upcomingSongs.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;

              return Container(
                margin: EdgeInsets.only(bottom: index == upcomingSongs.length - 1 ? 0 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  onTap: () async {
                    await player.playSong(song);
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      song['album_art'] ?? '',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 52,
                          height: 52,
                          color: Colors.white10,
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    song['title'] ?? 'Unknown Title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    song['artist'] ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
