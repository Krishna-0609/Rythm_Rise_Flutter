import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Consumer<SongPlayerProvider>(
        builder: (context, player, _) {
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.28),
                        const Color(0xff111523).withOpacity(0.85),
                        const Color(0xff0E1220),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _GlassIconButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          const Column(
                            children: [
                              Text(
                                'NOW PLAYING',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Rythm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
                                    song['id'].toString() == player.currentSongId,
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
                      const Spacer(),
                      Container(
                        height: 330,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
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
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              player.currentSongTitle ?? 'Unknown Title',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.currentArtist ?? 'Unknown Artist',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(
                                    Duration(milliseconds: sliderValue.toInt()),
                                  ),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  size: 34,
                                  onTap: player.playPrevious,
                                ),
                                _PrimaryPlayButton(
                                  isPlaying: player.isPlaying,
                                  onTap: player.togglePlayPause,
                                ),
                                _ControlIconButton(
                                  icon: Icons.skip_next_rounded,
                                  size: 34,
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
                      const SizedBox(height: 18),
                      Expanded(
                        flex: 2,
                        child:
                            player.currentLyrics != null &&
                                    player.currentLyrics!.isNotEmpty
                                ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      player.currentLyrics!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.75,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                                : Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(color: Colors.white10),
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
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color:
              active
                  ? AppColors.iconcolor2.withOpacity(0.9)
                  : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white),
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
        height: 76,
        width: 76,
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
          size: 42,
        ),
      ),
    );
  }
}
