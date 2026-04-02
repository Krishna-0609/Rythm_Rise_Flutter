import 'dart:ui';

import 'package:flutter/foundation.dart';
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
import '../theme/responsive_utils.dart';

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
    if (kIsWeb || ResponsiveUtils.isDesktop(context)) {
      return true;
    }

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
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.primary,
        body:
            isDesktop
                ? _DesktopShell(
                  selectedIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  child: _MainPageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    pages: _pages,
                  ),
                )
                : _MainPageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  pages: _pages,
                ),
        bottomNavigationBar:
            isDesktop
                ? null
                : Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GlobalMiniPlayer(show: _selectedIndex != 4),
                          _BottomNavBar(
                            selectedIndex: _selectedIndex,
                            onTap: _onItemTapped,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

class _MainPageView extends StatelessWidget {
  const _MainPageView({
    required this.controller,
    required this.onPageChanged,
    required this.pages,
  });

  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      onPageChanged: onPageChanged,
      physics: const BouncingScrollPhysics(),
      children: pages,
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final horizontalMargin = ResponsiveUtils.horizontalPadding(context) - 2;
    final compact = ResponsiveUtils.isCompact(context);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = ResponsiveUtils.isTablet(context) ? 560.0 : width;
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

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            margin: EdgeInsets.fromLTRB(
              horizontalMargin,
              0,
              horizontalMargin,
              8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.14),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 8,
                  vertical: compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  color: const Color(0xff151A2A).withOpacity(0.58),
                ),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = index == selectedIndex;

                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 7 : 9,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color:
                                selected
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.04 : 0.96,
                                duration: const Duration(milliseconds: 220),
                                child: _BottomNavIcon(
                                  item: item,
                                  selected: selected,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.white70,
                                  fontSize:
                                      selected
                                          ? (compact ? 10 : 11)
                                          : (compact ? 9 : 10),
                                  fontWeight:
                                      selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(item.label, maxLines: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
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
      final size = ResponsiveUtils.navIconSize(context, selected: true);
      return Image.asset(item.imageAsset, height: size, width: size);
    }

    if (item.inactiveAsset != null) {
      final size = ResponsiveUtils.navIconSize(context, selected: false);
      return Image.asset(
        item.inactiveAsset!,
        height: size,
        width: size,
        color: Colors.white70,
      );
    }

    return Icon(
      item.outlinedIcon,
      size: ResponsiveUtils.navIconSize(context, selected: false),
      color: Colors.white70,
    );
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

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.selectedIndex,
    required this.onTap,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Widget child;

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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.shellHorizontalPadding(context),
        ),
        child: Row(
          children: [
            _DesktopSidebar(
              items: items,
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.pageMaxWidth(context),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveUtils.pageMaxWidth(context),
                      ),
                      child: _GlobalMiniPlayer(show: selectedIndex != 4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<_NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xff111523).withOpacity(0.98),
              const Color(0xff1A2136).withOpacity(0.94),
            ],
          ),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: AppColors.iconcolor2),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rythm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'A cleaner web listening space with room to breathe.',
                style: TextStyle(color: Colors.white60, height: 1.45),
              ),
              const SizedBox(height: 24),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final selected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient:
                            selected
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xffF15C8E),
                                    Color(0xffEA8A4C),
                                  ],
                                )
                                : null,
                        color: selected ? null : Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color:
                              selected
                                  ? Colors.white24
                                  : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          _BottomNavIcon(item: item, selected: selected),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: selected ? Colors.white : Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalMiniPlayer extends StatelessWidget {
  const _GlobalMiniPlayer({required this.show});

  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }

    return Consumer<SongPlayerProvider>(
      builder: (context, player, _) {
        if (player.currentSongTitle == null) {
          return const SizedBox.shrink();
        }

        final durationMs =
            player.duration.inMilliseconds <= 0
                ? 1
                : player.duration.inMilliseconds;
        final progress = (player.position.inMilliseconds / durationMs).clamp(
          0.0,
          1.0,
        );

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NowPlayingPage()),
            );
          },
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    ResponsiveUtils.isDesktop(context)
                        ? ResponsiveUtils.pageMaxWidth(context)
                        : (ResponsiveUtils.isTablet(context)
                            ? 560
                            : double.infinity),
              ),
              child: Container(
                height: ResponsiveUtils.miniPlayerHeight(context),
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(context) - 2,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.74),
                      const Color(0xff2A1C35).withOpacity(0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.20),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.26),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(22),
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
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtils.isCompact(context) ? 10 : 12,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              player.currentAlbumArt ?? '',
                              width:
                                  ResponsiveUtils.isCompact(context) ? 44 : 50,
                              height:
                                  ResponsiveUtils.isCompact(context) ? 44 : 50,
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
                          SizedBox(
                            width: ResponsiveUtils.isCompact(context) ? 10 : 12,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.currentSongTitle ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveUtils.responsiveFont(
                                      context,
                                      compact: 12,
                                      regular: 13,
                                      tablet: 14,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  player.currentArtist ?? '',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: ResponsiveUtils.responsiveFont(
                                      context,
                                      compact: 11,
                                      regular: 12,
                                      tablet: 13,
                                    ),
                                  ),
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
                                size:
                                    ResponsiveUtils.isCompact(context)
                                        ? 22
                                        : 24,
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
            ),
          ),
        );
      },
    );
  }
}
