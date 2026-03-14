import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import 'liked_page.dart';
import 'now_playing_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _recentlyPlayedCount = 0;
  String _listenerName = 'Rythm Listener';
  String? _profileImageUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recently_played') ?? <String>[];
    final lastSongRaw = prefs.getString('last_song');
    final savedName = prefs.getString('profile_name')?.trim();
    final savedPhoto = prefs.getString('profile_photo')?.trim();

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

    if (!mounted) return;
    setState(() {
      _recentlyPlayedCount = recent.length;
      _listenerName = listenerName;
      _profileImageUrl = savedPhoto != null && savedPhoto.isNotEmpty ? savedPhoto : null;
      _loading = false;
    });
  }

  Future<void> _showEditProfileSheet() async {
    final nameController = TextEditingController(text: _listenerName);
    final photoController = TextEditingController(text: _profileImageUrl ?? '');

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
              const Text(
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
              TextField(
                controller: photoController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Profile photo URL'),
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _saveProfile(
                          nameController.text,
                          photoController.text,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Consumer<SongPlayerProvider>(
        builder: (context, player, _) {
          return RefreshIndicator(
            onRefresh: _loadProfileData,
            color: AppColors.iconcolor2,
            backgroundColor: AppColors.secondary,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _buildHeaderCard(player),
                const SizedBox(height: 20),
                _buildStatsSection(player),
                const SizedBox(height: 20),
                _buildQuickActions(context, player),
                const SizedBox(height: 20),
                _buildPreferencesCard(player),
                const SizedBox(height: 20),
                _buildAboutCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(SongPlayerProvider player) {
    final subtitle =
        player.currentSongTitle == null
            ? 'Build your perfect listening flow'
            : 'Now enjoying ${player.currentSongTitle}';

    return Container(
      padding: const EdgeInsets.all(22),
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
                height: 102,
                width: 102,
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
                            ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.person_rounded,
                                  size: 54,
                                  color: Colors.white,
                                );
                              },
                            )
                            : const Icon(
                              Icons.person_rounded,
                              size: 54,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
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
                  player.isPlaying ? Icons.graphic_eq : Icons.headphones_rounded,
                  color: AppColors.iconcolor1,
                ),
                const SizedBox(width: 10),
                Text(
                  player.isPlaying ? 'Playback active' : 'Ready to play',
                  style: const TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Music Space',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.25,
          children: [
            _StatTile(
              title: 'Favorites',
              value: '${player.favoriteSongs.length}',
              note: 'Songs you loved',
              icon: Icons.favorite_rounded,
              accent: AppColors.iconcolor2,
            ),
            _StatTile(
              title: 'Queue',
              value: '${player.playlist.length}',
              note: 'Tracks lined up',
              icon: Icons.queue_music_rounded,
              accent: AppColors.iconcolor1,
            ),
            _StatTile(
              title: 'Recent',
              value: _loading ? '...' : '$_recentlyPlayedCount',
              note: 'Recently played',
              icon: Icons.history_rounded,
              accent: const Color(0xff7AD7F0),
            ),
            _StatTile(
              title: 'Mode',
              value: player.isShuffle ? 'Mix' : 'Loop',
              note: player.isRepeat ? 'Repeat on' : 'Repeat off',
              icon: Icons.album_rounded,
              accent: const Color(0xffA0E57B),
            ),
          ],
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
            icon: player.isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
            title: 'Shuffle',
            subtitle: player.isShuffle ? 'Songs will play in mixed order' : 'Songs follow playlist order',
            trailing: Switch(
              value: player.isShuffle,
              activeColor: AppColors.iconcolor2,
              onChanged: (_) => player.toggleShuffle(),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _PreferenceTile(
            icon: player.isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            title: 'Repeat One',
            subtitle: player.isRepeat ? 'Current song repeats continuously' : 'Playback stops after queue ends',
            trailing: Switch(
              value: player.isRepeat,
              activeColor: AppColors.iconcolor1,
              onChanged: (_) => player.toggleRepeat(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _SectionCard(
      title: 'About Rythm',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rythm is your local streaming-style player with favorites, queue control, and full-screen playback.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 14,
            ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
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
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: trailing,
    );
  }
}
