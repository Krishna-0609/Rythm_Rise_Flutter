import 'package:flutter/material.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/english_song_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_beat_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_melody_song.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_new_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_vintage_page.dart';

import '../../../theme/app_colors.dart';

class LibraryMainPage extends StatelessWidget {
  const LibraryMainPage({super.key});

  @override
  Widget build(BuildContext context) {

    final List<Map<String, dynamic>> categories = [

      {
        "title": "Tamil Beat",
        "image":
        "https://res.cloudinary.com/dvhh2bbcp/image/upload/v1744786124/czkv7dyt069nidiypisl.jpg",
        "page": const TamilBeatPage()
      },

      {
        "title": "Tamil Melody",
        "image":
        "https://res.cloudinary.com/dvhh2bbcp/image/upload/v1744790653/bh5epl1posxhrly1wrrf.jpg",
        "page": const TamilMelodySong()
      },

      {
        "title": "Tamil New",
        "image":
        "https://akm-img-a-in.tosshub.com/indiatoday/images/story/202411/kissik-pushpa-2-song-243011625-16x9_0.jpg",
        "page": const TamilNewSong()
      },

      {
        "title": "Tamil Vintage",
        "image":
        "https://res.cloudinary.com/dvhh2bbcp/image/upload/v1744793369/rylvgdxbvozdbvxoyzo4.jpg",
        "page": const TamilVintageSong()
      },

      {
        "title": "Top English Songs",
        "image":
        "https://i.pinimg.com/474x/36/71/0f/36710f59079d9555d814a93bcf3fcbe7.jpg",
        "page": const EnglishSong()
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Library",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),

      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: categories.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => category["page"],
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  /// IMAGE
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        category["image"],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(
                              child: Icon(
                                Icons.music_note,
                                size: 40,
                                color: Colors.white54,
                              ),
                            ),
                      ),
                    ),
                  ),

                  /// TITLE
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(

                      category["title"],

                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
