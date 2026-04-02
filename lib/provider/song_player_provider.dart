import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});

  factory LyricLine.fromMap(Map<String, dynamic> map) {
    return LyricLine(
      timestamp: Duration(milliseconds: map['time'] ?? 0),
      text: map['line'] ?? '',
    );
  }
}

class SongPlayerProvider extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel(
    'rythm/native_player',
  );
  static const EventChannel _eventChannel = EventChannel('rythm/player_events');

  SongPlayerProvider() {
    _loadFavorites();
    restoreSleepTimer();
    _listenToNativeEvents();
  }

  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;

  String? _currentSongId;
  String? _currentSongTitle;
  String? _currentArtist;
  String? _currentAlbumArt;
  String? _currentSongUrl;
  String? _currentLyrics;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<LyricLine> _syncedLyrics = [];
  List<Map<String, dynamic>> _playlist = [];
  List<Map<String, dynamic>> _originalPlaylist = [];
  List<String> _queuedSongIds = [];
  List<Map<String, dynamic>> _favoriteSongs = [];

  int _currentIndex = -1;
  StreamSubscription<dynamic>? _eventSubscription;
  Timer? _sleepTimer;
  Timer? _sleepTicker;
  DateTime? _sleepTimerEndsAt;
  Duration _sleepTimerRemaining = Duration.zero;

  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isPlaying => _isPlaying;

  Duration get position => _position;
  Duration get duration => _duration;

  String? get currentSongId => _currentSongId;
  String? get currentSongTitle => _currentSongTitle;
  String? get currentArtist => _currentArtist;
  String? get currentAlbumArt => _currentAlbumArt;
  String? get currentSongUrl => _currentSongUrl;
  String? get currentLyrics => _currentLyrics;

  List<LyricLine> get syncedLyrics => _syncedLyrics;
  List<Map<String, dynamic>> get favoriteSongs => _favoriteSongs;
  List<Map<String, dynamic>> get playlist => List.unmodifiable(_playlist);
  List<Map<String, dynamic>> get upcomingSongs {
    if (_playlist.isEmpty || _currentIndex < 0) return const [];
    if (_currentIndex + 1 >= _playlist.length) return const [];
    return List.unmodifiable(_playlist.sublist(_currentIndex + 1));
  }
  List<Map<String, dynamic>> get queuedSongs {
    return _queuedSongIds
        .map(_songById)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
  Duration get sleepTimerRemaining => _sleepTimerRemaining;
  DateTime? get sleepTimerEndsAt => _sleepTimerEndsAt;
  bool get hasSleepTimer => _sleepTimerEndsAt != null;

  void _listenToNativeEvents() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      try {
        final map = Map<String, dynamic>.from(event as Map);

        _position = Duration(milliseconds: map['position'] ?? 0);
        final durationMs = ((map['duration'] ?? 0) as num).toInt();
        _duration = Duration(
          milliseconds: durationMs < 0 ? 0 : durationMs,
        );
        _isPlaying = map['isPlaying'] ?? false;
        _isShuffle = map['shuffle'] ?? false;
        _isRepeat = map['repeat'] ?? false;

        final nativeSongId = map['songId']?.toString();
        if (_playlist.isNotEmpty &&
            nativeSongId != null &&
            nativeSongId.isNotEmpty) {
          final playlistIndex = _playlist.indexWhere(
            (song) => song['id'].toString() == nativeSongId,
          );
          if (playlistIndex != -1) {
            _currentIndex = playlistIndex;
            _updateCurrentSong(_playlist[_currentIndex], notify: false);
            _syncQueuedSongsWithCurrent();
          }
        }

        notifyListeners();
      } catch (e) {
        debugPrint('Player event error: $e');
      }
    });
  }

  Future<void> setPlaylist(List<Map<String, dynamic>> songs) async {
    _originalPlaylist = List<Map<String, dynamic>>.from(songs);
    _playlist = List<Map<String, dynamic>>.from(songs);
    _queuedSongIds = [];

    if (_currentSongId != null) {
      final newIndex = _playlist.indexWhere(
        (song) => song['id'].toString() == _currentSongId,
      );
      if (newIndex != -1) {
        _currentIndex = newIndex;
      }
    }

    notifyListeners();
  }

  Future<void> playSong(Map<String, dynamic> song) async {
    var index = _playlist.indexWhere(
      (item) => item['id'].toString() == song['id'].toString(),
    );

    if (index == -1) {
      _playlist = [song];
      _originalPlaylist = [song];
      _queuedSongIds = [];
      index = 0;
    }

    _currentIndex = index;
    _updateCurrentSong(_playlist[_currentIndex], notify: false);
    _syncQueuedSongsWithCurrent();

    final nativeQueue = _buildNativeQueuePayload(_playlist);
    final nativeIndex = nativeQueue.indexWhere(
      (item) => item['id'].toString() == _currentSongId,
    );
    if (nativeIndex == -1) {
      debugPrint('Unable to play song: missing audio URL for ${song['title']}');
      return;
    }

    await _nativeChannel.invokeMethod('loadQueue', {
      'songsJson': jsonEncode(nativeQueue),
      'index': nativeIndex,
      'playWhenReady': true,
    });

    await _saveLastPlayed();
    await _updateRecentlyPlayed(song);
    notifyListeners();
  }

  Future<void> play() async {
    await _nativeChannel.invokeMethod('play');
  }

  Future<void> pause() async {
    await _nativeChannel.invokeMethod('pause');
  }

  Future<void> togglePlayPause() async {
    await _nativeChannel.invokeMethod('togglePlayPause');
  }

  Future<void> seek(Duration position) async {
    await _nativeChannel.invokeMethod('seek', {
      'position': position.inMilliseconds,
    });
  }

  Future<void> playNext() async {
    await _nativeChannel.invokeMethod('next');
  }

  Future<void> playPrevious() async {
    await _nativeChannel.invokeMethod('previous');
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    await _nativeChannel.invokeMethod('setShuffle', {'enabled': _isShuffle});
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    _isRepeat = !_isRepeat;
    await _nativeChannel.invokeMethod('setRepeat', {'enabled': _isRepeat});
    notifyListeners();
  }

  void addToQueue(Map<String, dynamic> song) {
    if (_playlist.isEmpty) {
      unawaited(playSong(song));
      return;
    }

    final songId = song['id']?.toString() ?? '';
    if (songId.isEmpty) return;
    if (songId == _currentSongId) return;

    final existsInQueue = _queuedSongIds.contains(songId);
    if (existsInQueue) return;

    final currentSongId = _currentSongId;
    final existsInPlaylist = _playlist.any(
      (item) => item['id'].toString() == song['id'].toString(),
    );
    if (existsInPlaylist) {
      _playlist.removeWhere((item) => item['id'].toString() == songId);
      if (currentSongId != null) {
        _currentIndex = _playlist.indexWhere(
          (item) => item['id'].toString() == currentSongId,
        );
      }
    }

    final insertIndex = (_currentIndex + 1 + _queuedSongIds.length).clamp(
      0,
      _playlist.length,
    );
    _playlist.insert(insertIndex, song);
    _queuedSongIds.add(songId);
    final nativeQueue = _buildNativeQueuePayload(_playlist);
    final nativeIndex = nativeQueue.indexWhere(
      (item) => item['id'].toString() == _currentSongId,
    );
    unawaited(
      _nativeChannel.invokeMethod('loadQueue', {
        'songsJson': jsonEncode(nativeQueue),
        'index': nativeIndex == -1 ? 0 : nativeIndex,
        'playWhenReady': _isPlaying,
      }),
    );
    notifyListeners();
  }

  Future<void> removeFromQueue(String songId) async {
    final queueIndex = _queuedSongIds.indexOf(songId);
    if (queueIndex == -1) return;

    _queuedSongIds.removeAt(queueIndex);
    _playlist.removeWhere((song) => song['id'].toString() == songId);
    if (_currentSongId != null) {
      _currentIndex = _playlist.indexWhere(
        (song) => song['id'].toString() == _currentSongId,
      );
    }

    final nativeQueue = _buildNativeQueuePayload(_playlist);
    final nativeIndex = nativeQueue.indexWhere(
      (item) => item['id'].toString() == _currentSongId,
    );

    await _nativeChannel.invokeMethod('loadQueue', {
      'songsJson': jsonEncode(nativeQueue),
      'index': nativeIndex == -1 ? 0 : nativeIndex,
      'playWhenReady': _isPlaying,
    });

    notifyListeners();
  }

  void toggleFavorite(Map<String, dynamic> song) async {
    final songId = song['id'].toString();
    final exists = _favoriteSongs.any(
      (item) => item['id'].toString() == songId,
    );

    if (exists) {
      _favoriteSongs.removeWhere((item) => item['id'].toString() == songId);
    } else {
      _favoriteSongs.add(song);
    }

    await _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _favoriteSongs.any((song) => song['id'].toString() == songId);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', jsonEncode(_favoriteSongs));
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('favorites');

    if (saved != null) {
      _favoriteSongs = List<Map<String, dynamic>>.from(jsonDecode(saved));
      notifyListeners();
    }
  }

  Future<void> setSleepTimer(Duration duration) async {
    if (duration <= Duration.zero) {
      await cancelSleepTimer();
      return;
    }

    final endAt = DateTime.now().add(duration);
    _startSleepTimer(endAt);
    await _persistSleepTimer();
  }

  Future<void> cancelSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimer = null;
    _sleepTicker = null;
    _sleepTimerEndsAt = null;
    _sleepTimerRemaining = Duration.zero;
    await _clearSleepTimerPersistence();
    notifyListeners();
  }

  Future<void> restoreSleepTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEndAt = prefs.getString('sleep_timer_end_at');
    if (rawEndAt == null || rawEndAt.isEmpty) return;

    final parsedEndAt = DateTime.tryParse(rawEndAt);
    if (parsedEndAt == null) {
      await _clearSleepTimerPersistence();
      return;
    }

    if (parsedEndAt.isBefore(DateTime.now())) {
      await _clearSleepTimerPersistence();
      return;
    }

    _startSleepTimer(parsedEndAt, persist: false);
  }

  Future<void> _updateRecentlyPlayed(Map<String, dynamic> song) async {
    final prefs = await SharedPreferences.getInstance();
    var recent = prefs.getStringList('recently_played') ?? <String>[];

    recent.removeWhere((item) {
      final map = jsonDecode(item);
      return map['id'].toString() == song['id'].toString();
    });

    recent.insert(0, jsonEncode(song));
    if (recent.length > 20) {
      recent = recent.sublist(0, 20);
    }

    await prefs.setStringList('recently_played', recent);
  }

  Future<void> _saveLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;

    await prefs.setString(
      'last_song',
      jsonEncode({
        'song': _playlist[_currentIndex],
        'position': _position.inMilliseconds,
      }),
    );
  }

  List<Map<String, dynamic>> _buildNativeQueuePayload(
    List<Map<String, dynamic>> songs,
  ) {
    return songs
        .map(
          (song) => <String, dynamic>{
            'id': song['id']?.toString() ?? '',
            'title': song['title']?.toString() ?? 'Unknown Title',
            'artist': song['artist']?.toString() ?? 'Unknown Artist',
            'url': song['url']?.toString() ?? '',
            'album_art': song['album_art']?.toString() ?? '',
          },
        )
        .where((song) => song['url']!.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _songById(String songId) {
    for (final song in _playlist) {
      if (song['id'].toString() == songId) {
        return song;
      }
    }
    return null;
  }

  void _syncQueuedSongsWithCurrent() {
    if (_queuedSongIds.isEmpty) return;

    _queuedSongIds = _queuedSongIds.where((songId) {
      final index = _playlist.indexWhere((song) => song['id'].toString() == songId);
      return index != -1 && index > _currentIndex;
    }).toList();
  }

  void _updateCurrentSong(Map<String, dynamic> song, {bool notify = true}) {
    _currentSongId = song['id'].toString();
    _currentSongTitle = song['title'] ?? 'Unknown Title';
    _currentArtist = song['artist'] ?? 'Unknown Artist';
    _currentAlbumArt = song['album_art']?.toString();
    _currentSongUrl = song['url']?.toString();
    _currentLyrics = song['lyrics']?.toString();
    _syncedLyrics = [];

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _startSleepTimer(DateTime endAt, {bool persist = true}) {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();

    _sleepTimerEndsAt = endAt;
    _updateSleepTimerRemaining();

    final remaining = endAt.difference(DateTime.now());
    _sleepTimer = Timer(remaining, () async {
      await pause();
      await cancelSleepTimer();
    });

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sleepTimerEndsAt == null) return;

      if (_sleepTimerEndsAt!.isBefore(DateTime.now())) {
        unawaited(() async {
          await pause();
          await cancelSleepTimer();
        }());
        return;
      }

      _updateSleepTimerRemaining();
      notifyListeners();
    });

    if (persist) {
      unawaited(_persistSleepTimer());
    }

    notifyListeners();
  }

  void _updateSleepTimerRemaining() {
    final endAt = _sleepTimerEndsAt;
    if (endAt == null) {
      _sleepTimerRemaining = Duration.zero;
      return;
    }

    final remaining = endAt.difference(DateTime.now());
    _sleepTimerRemaining =
        remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _persistSleepTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final endAt = _sleepTimerEndsAt;
    if (endAt == null) {
      await prefs.remove('sleep_timer_end_at');
      return;
    }

    await prefs.setString('sleep_timer_end_at', endAt.toIso8601String());
  }

  Future<void> _clearSleepTimerPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sleep_timer_end_at');
  }
}
