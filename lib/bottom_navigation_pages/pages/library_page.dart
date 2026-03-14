import 'package:flutter/material.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/english_song_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/library_main_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_beat_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_melody_song.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_new_page.dart';
import 'package:rythm/bottom_navigation_pages/pages/song_page/tamil_vintage_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: GlobalKey<NavigatorState>(),   // Prevents navigator conflicts
      initialRoute: '/libraryMain',
      onGenerateRoute: (RouteSettings settings) {

        Widget page;

        switch (settings.name) {

          case '/libraryMain':
            page = const LibraryMainPage();
            break;

          case '/tamilBeat':
            page = const TamilBeatPage();
            break;

          case '/tamilMelody':
            page = const TamilMelodySong();
            break;

          case '/tamilNew':
            page = const TamilNewSong();
            break;

          case '/tamilVintage':
            page = const TamilVintageSong();
            break;

          case '/englishSong':
            page = const EnglishSong();
            break;

          default:
            page = const LibraryMainPage();
        }

        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}