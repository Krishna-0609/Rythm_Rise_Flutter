import 'package:supabase_flutter/supabase_flutter.dart';

const int _songsPageSize = 1000;

Future<List<Map<String, dynamic>>> fetchAllSongs(
  SupabaseClient client,
  String table,
) async {
  final songs = <Map<String, dynamic>>[];
  var from = 0;

  while (true) {
    final to = from + _songsPageSize - 1;
    final response = await client.from(table).select('*').range(from, to);
    final page = List<Map<String, dynamic>>.from(response);

    songs.addAll(page);

    if (page.length < _songsPageSize) {
      break;
    }

    from += _songsPageSize;
  }

  return songs;
}
