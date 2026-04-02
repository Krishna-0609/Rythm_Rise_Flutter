import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/song_fetcher.dart';
import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_utils.dart';
import '../../widgets/adaptive_path_image.dart';
import '../../widgets/app_loading_widget.dart';
import 'liked_page.dart';
import 'now_playing_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _recentlyPlayedCount = 0;
  int? _librarySongCount;
  String _listenerName = 'Rythm Listener';
  String? _profileImageUrl;
  bool _loading = true;
  final TextEditingController _sleepHoursController = TextEditingController();
  final TextEditingController _sleepMinutesController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _sleepHoursController.dispose();
    _sleepMinutesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recently_played') ?? <String>[];
    final lastSongRaw = prefs.getString('last_song');
    final savedName = prefs.getString('profile_name')?.trim();
    final savedPhoto = prefs.getString('profile_photo')?.trim();
    var songCount = prefs.getInt('library_song_count');

    String listenerName = 'Rythm Listener';
    if (savedName != null && savedName.isNotEmpty) {
      listenerName = savedName;
    } else if (lastSongRaw != null) {
      try {
        final decoded = jsonDecode(lastSongRaw) as Map<String, dynamic>;
        final song = Map<String, dynamic>.from(decoded['song'] as Map);
        final artist = song['artist']?.toString().trim();
        if (artist != null && artist.isNotEmpty) {
          listenerName = artist;
        }
      } catch (_) {}
    }

    if (songCount == null) {
      try {
        final fetchedSongs = await fetchAllSongs(_supabase, 'songs');
        songCount = fetchedSongs.length;
        await prefs.setInt('library_song_count', songCount);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _recentlyPlayedCount = recent.length;
      _librarySongCount = songCount;
      _listenerName = listenerName;
      _profileImageUrl =
          savedPhoto != null && savedPhoto.isNotEmpty ? savedPhoto : null;
      _loading = false;
    });
  }

  Future<void> _showEditProfileSheet() async {
    final nameController = TextEditingController(text: _listenerName);
    String? selectedImagePath = _profileImageUrl;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Your name'),
              ),
              const SizedBox(height: 14),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return _ProfileImagePickerField(
                    imagePath: selectedImagePath,
                    onPickImage: () async {
                      final picked = await _pickImageFromGallery();
                      if (picked == null) return;
                      setModalState(() {
                        selectedImagePath = picked;
                      });
                    },
                    onClearImage:
                        selectedImagePath == null
                            ? null
                            : () {
                              setModalState(() {
                                selectedImagePath = null;
                              });
                            },
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _saveProfile(
                          nameController.text,
                          selectedImagePath ?? '',
                        );
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.iconcolor2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      return image?.path;
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.code == 'channel-error'
                  ? 'Image picker is not connected in the current app build. Please stop the app and run it again.'
                  : 'Unable to open gallery right now.',
            ),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile(String name, String photoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedName = name.trim();
    final trimmedPhoto = photoUrl.trim();

    if (trimmedName.isEmpty) {
      await prefs.remove('profile_name');
    } else {
      await prefs.setString('profile_name', trimmedName);
    }

    if (trimmedPhoto.isEmpty) {
      await prefs.remove('profile_photo');
    } else {
      await prefs.setString('profile_photo', trimmedPhoto);
    }

    if (!mounted) return;
    setState(() {
      _listenerName = trimmedName.isEmpty ? 'Rythm Listener' : trimmedName;
      _profileImageUrl = trimmedPhoto.isEmpty ? null : trimmedPhoto;
    });
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.iconcolor2),
      ),
    );
  }

  String _formatTimerLabel(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }

  String _formatRemaining(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPauseTime(DateTime? dateTime) {
    if (dateTime == null) return '--';

    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _applyCustomSleepTimer(SongPlayerProvider player) async {
    final hours = int.tryParse(_sleepHoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_sleepMinutesController.text.trim()) ?? 0;
    final duration = Duration(hours: hours, minutes: minutes);

    if (duration <= Duration.zero) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid timer duration first')),
      );
      return;
    }

    await player.setSleepTimer(duration);
    _sleepHoursController.clear();
    _sleepMinutesController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sleep timer set for ${_formatTimerLabel(duration)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final sectionGap = ResponsiveUtils.contentGap(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body:
          _loading
              ? const AppLoadingWidget()
              : Consumer<SongPlayerProvider>(
                builder: (context, player, _) {
                  return RefreshIndicator(
                    onRefresh: _loadProfileData,
                    color: AppColors.iconcolor2,
                    backgroundColor: AppColors.secondary,
                    child: ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        28,
                      ),
                      children: [
                        _buildHeaderCard(player),
                        SizedBox(height: sectionGap),
                        _buildStatsSection(player),
                        SizedBox(height: sectionGap),
                        _buildQuickActions(context, player),
                        SizedBox(height: sectionGap),
                        _buildPreferencesCard(player),
                        SizedBox(height: sectionGap),
                        _buildAboutCard(),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildHeaderCard(SongPlayerProvider player) {
    final context = this.context;
    final subtitle =
        player.currentSongTitle == null
            ? 'Build your perfect listening flow'
            : 'Now enjoying ${player.currentSongTitle}';

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.isCompact(context) ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xff2C314A), Color(0xff0F1321)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: ResponsiveUtils.isCompact(context) ? 88 : 102,
                width: ResponsiveUtils.isCompact(context) ? 88 : 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.iconcolor2, AppColors.iconcolor1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child:
                        _profileImageUrl != null
                            ? _ProfileImage(imagePath: _profileImageUrl!)
                            : Icon(
                              Icons.person_rounded,
                              size:
                                  ResponsiveUtils.isCompact(context) ? 46 : 54,
                              color: Colors.white,
                            ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: InkWell(
                  onTap: _showEditProfileSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.iconcolor2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _listenerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.responsiveFont(
                context,
                compact: 20,
                regular: 24,
                tablet: 28,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: ResponsiveUtils.responsiveFont(
                context,
                compact: 13,
                regular: 14,
                tablet: 15,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  player.isPlaying
                      ? Icons.graphic_eq
                      : Icons.headphones_rounded,
                  color: AppColors.iconcolor1,
                ),
                const SizedBox(width: 10),
                Text(
                  player.isPlaying ? 'Playback active' : 'Ready to play',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(SongPlayerProvider player) {
    final context = this.context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Music Space',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.responsiveFont(
              context,
              compact: 17,
              regular: 18,
              tablet: 20,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 600
                    ? 3
                    : 2;
            final aspectRatio = constraints.maxWidth < 360 ? 1.05 : 1.25;

            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: aspectRatio,
              children: [
                _StatTile(
                  title: 'Library',
                  value:
                      _librarySongCount == null ? '...' : '$_librarySongCount',
                  note: 'Songs in your collection',
                  icon: Icons.library_music_rounded,
                  accent: const Color(0xff9F86FF),
                ),
                _StatTile(
                  title: 'Favorites',
                  value: '${player.favoriteSongs.length}',
                  note: 'Songs you loved',
                  icon: Icons.favorite_rounded,
                  accent: AppColors.iconcolor2,
                ),
                _StatTile(
                  title: 'Queue',
                  value: '${player.queuedSongs.length}',
                  note: 'Songs queued next',
                  icon: Icons.queue_music_rounded,
                  accent: AppColors.iconcolor1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _QueuePage()),
                    );
                  },
                ),
                _StatTile(
                  title: 'Recent',
                  value: _loading ? '...' : '$_recentlyPlayedCount',
                  note: 'Recently played',
                  icon: Icons.history_rounded,
                  accent: const Color(0xff7AD7F0),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, SongPlayerProvider player) {
    return _SectionCard(
      title: 'Quick Actions',
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            subtitle: 'Change your name and profile photo',
            onTap: _showEditProfileSheet,
          ),
          const Divider(color: Colors.white12, height: 1),
          _ActionRow(
            icon: Icons.play_circle_fill_rounded,
            label: 'Open Now Playing',
            subtitle: 'Jump to the full player screen',
            onTap: () {
              if (player.currentSongTitle == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Play a song first')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NowPlayingPage()),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          _ActionRow(
            icon: Icons.favorite_rounded,
            label: 'Open Liked Songs',
            subtitle: 'See and play your favorite tracks',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LikedPage()),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          _ActionRow(
            icon: Icons.refresh_rounded,
            label: 'Refresh Profile',
            subtitle: 'Reload your local music stats',
            onTap: _loadProfileData,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(SongPlayerProvider player) {
    return _SectionCard(
      title: 'Playback Preferences',
      child: Column(
        children: [
          _PreferenceTile(
            icon:
                player.isShuffle
                    ? Icons.shuffle_on_rounded
                    : Icons.shuffle_rounded,
            title: 'Shuffle',
            subtitle:
                player.isShuffle
                    ? 'Songs will play in mixed order'
                    : 'Songs follow playlist order',
            trailing: Switch(
              value: player.isShuffle,
              activeColor: AppColors.iconcolor2,
              onChanged: (_) => player.toggleShuffle(),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _PreferenceTile(
            icon:
                player.isRepeat
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
            title: 'Repeat One',
            subtitle:
                player.isRepeat
                    ? 'Current song repeats continuously'
                    : 'Playback stops after queue ends',
            trailing: Switch(
              value: player.isRepeat,
              activeColor: AppColors.iconcolor1,
              onChanged: (_) => player.toggleRepeat(),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildSleepTimerSection(player),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimerSection(SongPlayerProvider player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.08),
              child: const Icon(Icons.timer_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player.hasSleepTimer
                        ? 'Pauses music automatically at ${_formatPauseTime(player.sleepTimerEndsAt)}'
                        : 'Pick a countdown and Rythm will pause your song for you',
                    style: const TextStyle(color: Colors.white60, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(player.hasSleepTimer ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  player.hasSleepTimer
                      ? AppColors.iconcolor2.withOpacity(0.45)
                      : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors:
                        player.hasSleepTimer
                            ? [
                              AppColors.iconcolor2.withOpacity(0.9),
                              AppColors.iconcolor1.withOpacity(0.9),
                            ]
                            : [Colors.white12, Colors.white10],
                  ),
                ),
                child: Icon(
                  player.hasSleepTimer
                      ? Icons.nightlight_round
                      : Icons.play_circle_outline_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.hasSleepTimer
                          ? _formatRemaining(player.sleepTimerRemaining)
                          : 'No timer active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.responsiveFont(
                          context,
                          compact: 16,
                          regular: 18,
                          tablet: 19,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.hasSleepTimer
                          ? 'Playback will pause automatically'
                          : 'Choose how long the music should keep playing',
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (player.hasSleepTimer)
                TextButton(
                  onPressed: () {
                    player.cancelSleepTimer();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.iconcolor1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sleepHoursController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _timerInputDecoration('Hours'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sleepMinutesController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _timerInputDecoration('Minutes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _applyCustomSleepTimer(player);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iconcolor2,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Set Custom Timer',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _timerInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.iconcolor2),
      ),
    );
  }

  Widget _buildAboutCard() {
    return _SectionCard(
      title: 'About Rythm',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rythm is your local streaming-style player with favorites, queue control, and full-screen playback.',
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: AppColors.iconcolor1),
              SizedBox(width: 10),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_rounded,
      size: ResponsiveUtils.isCompact(context) ? 46 : 54,
      color: Colors.white,
    );

    return AdaptivePathImage(
      path: imagePath,
      fit: BoxFit.cover,
      fallback: fallback,
    );
  }
}

class _ProfileImagePickerField extends StatelessWidget {
  const _ProfileImagePickerField({
    required this.onPickImage,
    this.imagePath,
    this.onClearImage,
  });

  final String? imagePath;
  final VoidCallback onPickImage;
  final VoidCallback? onClearImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile photo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.iconcolor2, AppColors.iconcolor1],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child:
                      hasImage
                          ? _ProfileImage(imagePath: imagePath!)
                          : Container(
                            color: Colors.white.withOpacity(0.08),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white70,
                              size: 46,
                            ),
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iconcolor2,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasImage ? 'Change Photo' : 'Choose From Device'),
                ),
              ),
              if (onClearImage != null) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onClearImage,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.isCompact(context) ? 16 : 18),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.responsiveFont(
                context,
                compact: 15,
                regular: 17,
                tablet: 18,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.isCompact(context) ? 14 : 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withOpacity(0.18),
              child: Icon(icon, color: accent),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.responsiveFont(
                  context,
                  compact: 20,
                  regular: 24,
                  tablet: 26,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.responsiveFont(
                  context,
                  compact: 13,
                  regular: 14,
                  tablet: 15,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(
                color: Colors.white60,
                fontSize: ResponsiveUtils.responsiveFont(
                  context,
                  compact: 11,
                  regular: 12,
                  tablet: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuePage extends StatelessWidget {
  const _QueuePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: Text(
          'Your Queue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<SongPlayerProvider>(
        builder: (context, player, _) {
          final queueSongs = player.queuedSongs;

          if (queueSongs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No songs are queued yet. Use "Add to Queue" on any song and it will play after the current track.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              14,
              ResponsiveUtils.horizontalPadding(context),
              24,
            ),
            itemCount: queueSongs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final song = queueSongs[index];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  onTap: () async {
                    await player.playSong(song);
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      song['album_art'] ?? '',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 56,
                          height: 56,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${index + 1}. ${song['artist'] ?? 'Unknown Artist'}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: IconButton(
                    onPressed:
                        () => player.removeFromQueue(song['id'].toString()),
                    icon: Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.08),
        child: Icon(icon, color: AppColors.iconcolor1),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveUtils.responsiveFont(
            context,
            compact: 14,
            regular: 15,
            tablet: 16,
          ),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white60,
          fontSize: ResponsiveUtils.responsiveFont(
            context,
            compact: 12,
            regular: 13,
            tablet: 14,
          ),
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white54),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.08),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveUtils.responsiveFont(
            context,
            compact: 14,
            regular: 15,
            tablet: 16,
          ),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white60,
          fontSize: ResponsiveUtils.responsiveFont(
            context,
            compact: 12,
            regular: 13,
            tablet: 14,
          ),
        ),
      ),
      trailing: trailing,
    );
  }
}
