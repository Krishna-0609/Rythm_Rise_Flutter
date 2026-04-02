import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/artist_playlist_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/english_song_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_beat_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_melody_song.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_new_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_vintage_page.dart';
import 'package:rythm/provider/custom_playlist_provider.dart';
import 'package:rythm/provider/song_player_provider.dart';
import 'package:rythm/widgets/adaptive_path_image.dart';
import 'package:rythm/widgets/song_action_sheet.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/responsive_utils.dart';

class LibraryMainPage extends StatelessWidget {
  const LibraryMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = <_LibraryCategory>[
      _LibraryCategory(
        title: 'Tamil Beat',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1744786124/czkv7dyt069nidiypisl.jpg',
        page: TamilBeatPage(),
      ),
      _LibraryCategory(
        title: 'Tamil Melody',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1744790653/bh5epl1posxhrly1wrrf.jpg',
        page: TamilMelodySong(),
      ),
      _LibraryCategory(
        title: 'Tamil New',
        imageUrl:
            'https://akm-img-a-in.tosshub.com/indiatoday/images/story/202411/kissik-pushpa-2-song-243011625-16x9_0.jpg',
        page: TamilNewSong(),
      ),
      _LibraryCategory(
        title: 'Tamil Vintage',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1744793369/rylvgdxbvozdbvxoyzo4.jpg',
        page: TamilVintageSong(),
      ),
      _LibraryCategory(
        title: 'Top English Songs',
        imageUrl:
            'https://i.pinimg.com/474x/36/71/0f/36710f59079d9555d814a93bcf3fcbe7.jpg',
        page: EnglishSong(),
      ),
      _LibraryCategory(
        title: 'Anirudh Hits',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774342003/lplsissuxry24ky5r0j4.jpg',
        page: ArtistPlaylistPage(
          title: 'Anirudh Hits',
          artistKeywords: ['anirudh'],
        ),
      ),
      _LibraryCategory(
        title: 'Hiphop Tamizha',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774343456/jka8fwhjt6dw8jp7mcwk.jpg',
        page: ArtistPlaylistPage(
          title: 'Hiphop Tamizha',
          artistKeywords: [
            'hiphop tamizha',
            'hip hop tamizha',
            'hiphop tamila',
            'hip hop tamila',
          ],
        ),
      ),
      _LibraryCategory(
        title: 'Sid Sriram',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774343721/zqcqfqb9jvqqulwimx18.jpg',
        page: ArtistPlaylistPage(
          title: 'Sid Sriram',
          artistKeywords: ['sid sriram'],
        ),
      ),
      _LibraryCategory(
        title: 'Ilaiyaraaja Hits',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774432318/kmf6hmqlup22luzzkxnv.jpg',
        page: ArtistPlaylistPage(
          title: 'Ilaiyaraaja Hits',
          artistKeywords: ['Ilaiyaraaja'],
        ),
      ),
      _LibraryCategory(
        title: 'S.P.Balasubrahmanyam',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774442495/jl91hbadje1ozprnajml.jpg',
        page: ArtistPlaylistPage(
          title: 'S.P.Balasubrahmanyam',
          artistKeywords: ['S.P.Balasubrahmanyam', "S.P.B"],
        ),
      ),
      _LibraryCategory(
        title: 'A.R.Rahman Hits',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774507273/jk5jourft28wqni7vkvl.jpg',
        page: ArtistPlaylistPage(
          title: 'A.R.Rahman Hits',
          artistKeywords: ['A.R.Rahman'],
        ),
      ),
      _LibraryCategory(
        title: 'G.V.Prakash Hits',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774612639/j23svngsecytau56hm5n.jpg',
        page: ArtistPlaylistPage(
          title: 'G.V.Prakash Hits',
          artistKeywords: ['G.V.Pragash', 'G. V. Prakash Kumar', 'G.V'],
        ),
      ),
      _LibraryCategory(
        title: 'Yuvan Shankar Raja',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774614308/optgcdeqkgb07i1sxdzb.jpg',
        page: ArtistPlaylistPage(
          title: 'Yuvan Shankar Raja',
          artistKeywords: ['Yuvan Shankar Raja', 'Yuvan', 'U1'],
        ),
      ),
      _LibraryCategory(
        title: 'Shreya Ghoshal',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774614922/wxjro9ladd6jk26yxvkm.jpg',
        page: ArtistPlaylistPage(
          title: 'Shreya Ghoshal',
          artistKeywords: ['Shreya Ghoshal'],
        ),
      ),
      _LibraryCategory(
        title: 'Mano Hits',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774615253/qqshrwcolzn9okqpcifr.jpg',
        page: ArtistPlaylistPage(title: 'Mano Hits', artistKeywords: ['Mano']),
      ),

      _LibraryCategory(
        title: 'S. Janaki',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774616117/erzjy6rvtfj7nciuyc0z.jpg',
        page: ArtistPlaylistPage(
          title: 'S. Janaki',
          artistKeywords: ['S. Janaki', 'Janaki'],
        ),
      ),
      _LibraryCategory(
        title: 'Harris Jayaraj',
        imageUrl:
            'https://res.cloudinary.com/dvhh2bbcp/image/upload/v1774701967/fxd7abvr6onzer1hwtp1.jpg',
        page: ArtistPlaylistPage(
          title: 'Harris Jayaraj',
          artistKeywords: ['Harris Jayaraj'],
        ),
      ),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          centerTitle: true,
          toolbarHeight: 86,
          elevation: 0,
          backgroundColor: AppColors.primary,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Library',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  fontSize: ResponsiveUtils.responsiveFont(
                    context,
                    compact: 23,
                    regular: 25,
                    tablet: 27,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Curated picks and your personal collections',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(88),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                0,
                ResponsiveUtils.horizontalPadding(context),
                16,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: BorderRadius.circular(18),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.iconcolor2,
                        Color(0xffFF8A5B),
                        AppColors.iconcolor1,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.iconcolor2.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    _LibraryTabChip(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Curated',
                      subtitle: 'Ready to play',
                    ),
                    _LibraryTabChip(
                      icon: Icons.library_music_rounded,
                      title: 'Yours',
                      subtitle: 'Custom mixes',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _PreloadedLibraryTab(categories: categories),
            const _CustomLibraryTab(),
          ],
        ),
      ),
    );
  }
}

class _PreloadedLibraryTab extends StatelessWidget {
  const _PreloadedLibraryTab({required this.categories});

  final List<_LibraryCategory> categories;

  @override
  Widget build(BuildContext context) {
    final bottomInset = _libraryBottomInset(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveUtils.adaptiveGridColumns(
          context,
          compact: 2,
          regular: 2,
          tablet: 3,
          desktop: 4,
        );
        final aspectRatio = constraints.maxWidth < 360 ? 0.82 : 0.75;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.horizontalPadding(context),
            ResponsiveUtils.horizontalPadding(context),
            ResponsiveUtils.horizontalPadding(context),
            bottomInset,
          ),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => category.page),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          category.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 40,
                                  color: Colors.white54,
                                ),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        category.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.responsiveFont(
                            context,
                            compact: 13,
                            regular: 14,
                            tablet: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LibraryCategory {
  const _LibraryCategory({
    required this.title,
    required this.imageUrl,
    required this.page,
  });

  final String title;
  final String imageUrl;
  final Widget page;
}

class _LibraryTabChip extends StatelessWidget {
  const _LibraryTabChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveUtils.isCompact(context);

    return SizedBox(
      height: compact ? 66 : 70,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 34 : 38,
              height: compact ? 34 : 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: compact ? 18 : 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveUtils.responsiveFont(
                        context,
                        compact: 10,
                        regular: 11,
                        tablet: 12,
                      ),
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

class _CustomLibraryTab extends StatelessWidget {
  const _CustomLibraryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomPlaylistProvider>(
      builder: (context, playlists, _) {
        final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
        final compact = ResponsiveUtils.isCompact(context);
        final bottomInset = _libraryBottomInset(context);

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            bottomInset,
          ),
          children: [
            _CreatePlaylistCard(onTap: () => _showCreatePlaylistSheet(context)),
            const SizedBox(height: 18),
            if (playlists.playlists.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.queue_music_rounded,
                      size: 52,
                      color: Colors.white38,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No custom playlists yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your own playlist with a custom name and album art, then add songs from anywhere in the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, height: 1.5),
                    ),
                  ],
                ),
              )
            else
              ...playlists.playlists.map((playlist) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: 8,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => _CustomPlaylistDetailPage(
                                playlistId: playlist.id,
                              ),
                        ),
                      );
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _PlaylistCover(
                        imageUrl: playlist.imageUrl,
                        size: compact ? 56 : 62,
                      ),
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${playlist.songs.length} songs',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white54,
                      ),
                      onPressed:
                          () => _confirmDeletePlaylist(
                            context,
                            playlists,
                            playlist,
                          ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _showCreatePlaylistSheet(BuildContext context) async {
    final nameController = TextEditingController();
    String? selectedImagePath;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              14,
              14,
              mediaQuery.viewInsets.bottom + 18,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xff14192A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Create Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Make a custom playlist with your own title and cover art.',
                      style: TextStyle(color: Colors.white60, height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    _ElegantInputField(
                      controller: nameController,
                      hintText: 'Playlist name',
                      icon: Icons.library_music_rounded,
                    ),
                    const SizedBox(height: 14),
                    StatefulBuilder(
                      builder: (context, setModalState) {
                        return _ImagePickerField(
                          label: 'Playlist cover',
                          imagePath: selectedImagePath,
                          placeholderIcon: Icons.photo_library_outlined,
                          buttonLabel:
                              selectedImagePath == null
                                  ? 'Choose From Device'
                                  : 'Change Image',
                          onPickImage: () async {
                            final picked = await _pickImageFromGallery(context);
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await context
                              .read<CustomPlaylistProvider>()
                              .createPlaylist(
                                name: nameController.text,
                                imageUrl: selectedImagePath ?? '',
                              );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.iconcolor2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Create Playlist',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
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

  Future<String?> _pickImageFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      return image?.path;
    } on PlatformException catch (error) {
      if (context.mounted) {
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

  Future<void> _confirmDeletePlaylist(
    BuildContext context,
    CustomPlaylistProvider playlists,
    CustomPlaylist playlist,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff14192A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete Playlist?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await playlists.deletePlaylist(playlist.id);
    }
  }
}

class _CreatePlaylistCard extends StatelessWidget {
  const _CreatePlaylistCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff212944), Color(0xff111522)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.iconcolor2,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Custom Playlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add your own playlist name, cover art, and build multiple personal collections.',
                    style: TextStyle(color: Colors.white60, height: 1.4),
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

class _ElegantInputField extends StatelessWidget {
  const _ElegantInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.white.withOpacity(0.08),
        child: const Icon(Icons.queue_music_rounded, color: Colors.white70),
      );
    }

    return AdaptivePathImage(
      path: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      fallback: Container(
        width: size,
        height: size,
        color: Colors.white.withOpacity(0.08),
        child: const Icon(Icons.queue_music_rounded, color: Colors.white70),
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.label,
    required this.placeholderIcon,
    required this.buttonLabel,
    required this.onPickImage,
    this.imagePath,
    this.onClearImage,
  });

  final String label;
  final String? imagePath;
  final IconData placeholderIcon;
  final String buttonLabel;
  final VoidCallback onPickImage;
  final VoidCallback? onClearImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 164,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.04),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child:
                  hasImage
                      ? AdaptivePathImage(
                        path: imagePath!,
                        fit: BoxFit.cover,
                        fallback: _ImagePlaceholder(icon: placeholderIcon),
                      )
                      : _ImagePlaceholder(icon: placeholderIcon),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iconcolor2,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(buttonLabel),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white38, size: 40),
          const SizedBox(height: 10),
          const Text(
            'No image selected',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

double _libraryBottomInset(BuildContext context) {
  final hasMiniPlayer = context.select<SongPlayerProvider, bool>(
    (player) => player.currentSongTitle != null,
  );

  final baseNavSpace = ResponsiveUtils.isCompact(context) ? 118.0 : 128.0;
  final miniPlayerSpace =
      hasMiniPlayer ? ResponsiveUtils.miniPlayerHeight(context) + 18 : 0.0;

  return MediaQuery.paddingOf(context).bottom + baseNavSpace + miniPlayerSpace;
}

class _CustomPlaylistDetailPage extends StatelessWidget {
  const _CustomPlaylistDetailPage({required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return Consumer2<CustomPlaylistProvider, SongPlayerProvider>(
      builder: (context, playlists, player, _) {
        final playlist = playlists.playlists.firstWhere(
          (item) => item.id == playlistId,
          orElse:
              () => const CustomPlaylist(
                id: '',
                name: 'Playlist',
                imageUrl: '',
                songs: [],
              ),
        );

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Text(
              playlist.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _PlaylistCover(
                        imageUrl: playlist.imageUrl,
                        size: 86,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${playlist.songs.length} songs in this custom playlist',
                            style: const TextStyle(color: Colors.white60),
                          ),
                          const SizedBox(height: 12),
                          if (playlist.songs.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () async {
                                await player.setPlaylist(playlist.songs);
                                await player.playSong(playlist.songs.first);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.iconcolor2,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play Playlist'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (playlist.songs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'No songs added yet. Use the song options menu and tap "Add to Playlist".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, height: 1.5),
                  ),
                )
              else
                ...playlist.songs.map((song) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await player.setPlaylist(playlist.songs);
                        await player.playSong(song);
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              song['album_art'] ?? '',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      color: Colors.white70,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title'] ?? 'Unknown Title',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song['artist'] ?? 'Unknown Artist',
                                  style: const TextStyle(color: Colors.white60),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              showSongActionSheet(
                                context: context,
                                song: song,
                                playlist: playlist.songs,
                                customPlaylistId: playlist.id,
                                customPlaylistName: playlist.name,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
