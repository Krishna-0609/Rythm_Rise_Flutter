import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rythm/bottom_navigation_pages/pages/home.dart';
import 'package:rythm/bottom_navigation_pages/pages/library_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/liked_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/profile_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/search_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/now_playing_page.dart';

import '../provider/song_player_provider.dart';
import '../theme/app_colors.dart';

class BottomPages extends StatefulWidget {
  const BottomPages({super.key});

  @override
  State<BottomPages> createState() => _BottomPagesState();
}

class _BottomPagesState extends State<BottomPages> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  final List<Widget> _pages = const [
    Home(key: PageStorageKey('HomePage')),
    SearchPage(key: PageStorageKey('SearchPage')),
    LikedPage(key: PageStorageKey('LikedPage')),
    LibraryPage(key: PageStorageKey('LibraryPage')),
    ProfilePage(key: PageStorageKey('ProfilePage')),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  Future<bool> _onBackPressed() async {
    final exitApp = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.primary,
            title: const Text(
              'Exit App',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: const Text(
              'Are you sure you want to exit?',
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Exit',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    return exitApp ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _GlobalMiniPlayer(),
              _BottomNavBar(selectedIndex: _selectedIndex, onTap: _onItemTapped),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItemData>[
      const _NavItemData(
        label: 'Home',
        outlinedIcon: Icons.home_outlined,
        imageAsset: 'assets/Home_icon.png',
      ),
      const _NavItemData(
        label: 'Search',
        outlinedIcon: Icons.search_outlined,
        imageAsset: 'assets/Search_icon.png',
      ),
      const _NavItemData(
        label: 'Liked',
        outlinedIcon: Icons.favorite_border_rounded,
        imageAsset: 'assets/Selected_Heart.png',
        inactiveAsset: 'assets/Heart_Icon.png',
      ),
      const _NavItemData(
        label: 'Library',
        outlinedIcon: Icons.library_music_outlined,
        imageAsset: 'assets/library.png',
        inactiveAsset: 'assets/library.png',
      ),
      const _NavItemData(
        label: 'Profile',
        outlinedIcon: Icons.person_outline_rounded,
        imageAsset: 'assets/customer.png',
        inactiveAsset: 'assets/customer.png',
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == selectedIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color:
                      selected
                          ? Colors.white.withOpacity(0.07)
                          : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.05 : 0.96,
                      duration: const Duration(milliseconds: 220),
                      child: _BottomNavIcon(item: item, selected: selected),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: selected ? 11.5 : 10.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      child: Text(item.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({required this.item, required this.selected});

  final _NavItemData item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Image.asset(item.imageAsset, height: 34, width: 34);
    }

    if (item.inactiveAsset != null) {
      return Image.asset(
        item.inactiveAsset!,
        height: 28,
        width: 28,
        color: Colors.white54,
      );
    }

    return Icon(item.outlinedIcon, size: 29, color: Colors.white54);
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.outlinedIcon,
    required this.imageAsset,
    this.inactiveAsset,
  });

  final String label;
  final IconData outlinedIcon;
  final String imageAsset;
  final String? inactiveAsset;
}

class _GlobalMiniPlayer extends StatelessWidget {
  const _GlobalMiniPlayer();

  @override
  Widget build(BuildContext context) {
    return Consumer<SongPlayerProvider>(
      builder: (context, player, _) {
        if (player.currentSongTitle == null) {
          return const SizedBox.shrink();
        }

        final durationMs =
            player.duration.inMilliseconds <= 0 ? 1 : player.duration.inMilliseconds;
        final progress =
            (player.position.inMilliseconds / durationMs).clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NowPlayingPage()),
            );
          },
          child: Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.72),
                  const Color(0xff2A1C35).withOpacity(0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.iconcolor2,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          player.currentAlbumArt ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 35,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.currentSongTitle ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              player.currentArtist ?? '',
                              style: const TextStyle(color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          onPressed: player.togglePlayPause,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
