import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/song_fetcher.dart';
import '../../provider/song_player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_utils.dart';
import '../../widgets/app_loading_widget.dart';
import '../../widgets/song_action_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum _SearchSort { relevance, titleAz, artistAz }

class _SearchPageState extends State<SearchPage> {
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> allSongs = [];
  List<Map<String, dynamic>> filteredSongs = [];

  bool isLoading = true;
  bool _searchTitle = true;
  bool _searchArtist = true;
  bool _searchAlbum = true;
  bool _searchLyrics = false;
  bool _searchLanguage = true;
  bool _searchGenre = true;
  String? _selectedLanguage;
  String? _selectedGenre;
  _SearchSort _sort = _SearchSort.relevance;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await fetchAllSongs(
        Supabase.instance.client,
        'songs',
      );

      if (!mounted) return;

      setState(() {
        allSongs = List<Map<String, dynamic>>.from(response);
        filteredSongs = List<Map<String, dynamic>>.from(allSongs);
        isLoading = false;
      });

      _applyFilters(immediate: true);
    } catch (e) {
      debugPrint('Error fetching songs: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _applyFilters({bool immediate = false}) {
    if (!immediate) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 260), () {
        if (mounted) {
          _runFiltering();
        }
      });
      return;
    }

    _runFiltering();
  }

  void _runFiltering() {
    final query = _controller.text.trim().toLowerCase();

    final results = allSongs.where((song) {
      final matchesQuery =
          query.isEmpty ? true : _songScore(song, query: query) > 0;
      if (!matchesQuery) return false;

      final language = _songField(song, const [
        'language',
        'lang',
        'category',
      ]).toLowerCase();
      final genre = _songField(song, const [
        'genre',
        'mood',
        'type',
        'playlist',
      ]).toLowerCase();

      final matchesLanguage =
          _selectedLanguage == null || language == _selectedLanguage;
      final matchesGenre = _selectedGenre == null || genre == _selectedGenre;

      return matchesLanguage && matchesGenre;
    }).toList();

    results.sort((a, b) {
      switch (_sort) {
        case _SearchSort.titleAz:
          return _songField(a, const ['title']).toLowerCase().compareTo(
            _songField(b, const ['title']).toLowerCase(),
          );
        case _SearchSort.artistAz:
          return _songField(a, const ['artist']).toLowerCase().compareTo(
            _songField(b, const ['artist']).toLowerCase(),
          );
        case _SearchSort.relevance:
          final scoreB = _songScore(b, query: query);
          final scoreA = _songScore(a, query: query);
          if (scoreB != scoreA) {
            return scoreB.compareTo(scoreA);
          }
          return _songField(a, const ['title']).toLowerCase().compareTo(
            _songField(b, const ['title']).toLowerCase(),
          );
      }
    });

    setState(() => filteredSongs = results);
  }

  int _songScore(Map<String, dynamic> song, {required String query}) {
    if (query.isEmpty) return 1;

    var score = 0;

    int scoreField(String value, int exact, int partial) {
      final normalized = value.toLowerCase();
      if (normalized.isEmpty) return 0;
      if (normalized == query) return exact;
      if (normalized.startsWith(query)) return partial + 2;
      if (normalized.contains(query)) return partial;
      return 0;
    }

    if (_searchTitle) {
      score += scoreField(_songField(song, const ['title', 'name']), 14, 10);
    }
    if (_searchArtist) {
      score += scoreField(_songField(song, const ['artist', 'singer']), 12, 8);
    }
    if (_searchAlbum) {
      score += scoreField(_songField(song, const ['album', 'movie']), 8, 5);
    }
    if (_searchLyrics) {
      score += scoreField(_songField(song, const ['lyrics', 'description']), 5, 3);
    }
    if (_searchLanguage) {
      score += scoreField(_songField(song, const ['language', 'lang']), 6, 4);
    }
    if (_searchGenre) {
      score += scoreField(_songField(song, const ['genre', 'mood', 'type']), 6, 4);
    }

    return score;
  }

  String _songField(Map<String, dynamic> song, List<String> keys) {
    for (final key in keys) {
      final value = song[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<String> _topValues(List<String> keys) {
    final counts = <String, int>{};

    for (final song in allSongs) {
      final value = _songField(song, keys).trim().toLowerCase();
      if (value.isEmpty || value == 'unknown') continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });

    return entries.take(8).map((entry) => entry.key).toList();
  }

  Future<void> _openAdvancedSearchSheet() async {
    var searchTitle = _searchTitle;
    var searchArtist = _searchArtist;
    var searchAlbum = _searchAlbum;
    var searchLyrics = _searchLyrics;
    var searchLanguage = _searchLanguage;
    var searchGenre = _searchGenre;
    var selectedLanguage = _selectedLanguage;
    var selectedGenre = _selectedGenre;
    var sort = _sort;

    final languages = _topValues(const ['language', 'lang', 'category']);
    final genres = _topValues(const ['genre', 'mood', 'type', 'playlist']);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(12),
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewPadding.bottom + 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xff121726),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      'Advanced Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose where to search and how to refine the results.',
                      style: TextStyle(color: Colors.white60, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    _buildModalTitle('Search In'),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterToggleChip(
                          label: 'Title',
                          selected: searchTitle,
                          onTap: () => setModalState(() => searchTitle = !searchTitle),
                        ),
                        _FilterToggleChip(
                          label: 'Artist',
                          selected: searchArtist,
                          onTap: () => setModalState(() => searchArtist = !searchArtist),
                        ),
                        _FilterToggleChip(
                          label: 'Album',
                          selected: searchAlbum,
                          onTap: () => setModalState(() => searchAlbum = !searchAlbum),
                        ),
                        _FilterToggleChip(
                          label: 'Lyrics',
                          selected: searchLyrics,
                          onTap: () => setModalState(() => searchLyrics = !searchLyrics),
                        ),
                        _FilterToggleChip(
                          label: 'Language',
                          selected: searchLanguage,
                          onTap: () =>
                              setModalState(() => searchLanguage = !searchLanguage),
                        ),
                        _FilterToggleChip(
                          label: 'Genre',
                          selected: searchGenre,
                          onTap: () => setModalState(() => searchGenre = !searchGenre),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildModalTitle('Sort By'),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterToggleChip(
                          label: 'Relevance',
                          selected: sort == _SearchSort.relevance,
                          onTap: () =>
                              setModalState(() => sort = _SearchSort.relevance),
                        ),
                        _FilterToggleChip(
                          label: 'Title A-Z',
                          selected: sort == _SearchSort.titleAz,
                          onTap: () =>
                              setModalState(() => sort = _SearchSort.titleAz),
                        ),
                        _FilterToggleChip(
                          label: 'Artist A-Z',
                          selected: sort == _SearchSort.artistAz,
                          onTap: () =>
                              setModalState(() => sort = _SearchSort.artistAz),
                        ),
                      ],
                    ),
                    if (languages.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildModalTitle('Language Filter'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FilterToggleChip(
                            label: 'All',
                            selected: selectedLanguage == null,
                            onTap: () => setModalState(() => selectedLanguage = null),
                          ),
                          ...languages.map((language) {
                            return _FilterToggleChip(
                              label: _labelize(language),
                              selected: selectedLanguage == language,
                              onTap: () =>
                                  setModalState(() => selectedLanguage = language),
                            );
                          }),
                        ],
                      ),
                    ],
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildModalTitle('Genre Filter'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FilterToggleChip(
                            label: 'All',
                            selected: selectedGenre == null,
                            onTap: () => setModalState(() => selectedGenre = null),
                          ),
                          ...genres.map((genre) {
                            return _FilterToggleChip(
                              label: _labelize(genre),
                              selected: selectedGenre == genre,
                              onTap: () => setModalState(() => selectedGenre = genre),
                            );
                          }),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _searchTitle = true;
                                _searchArtist = true;
                                _searchAlbum = true;
                                _searchLyrics = false;
                                _searchLanguage = true;
                                _searchGenre = true;
                                _selectedLanguage = null;
                                _selectedGenre = null;
                                _sort = _SearchSort.relevance;
                              });
                              _applyFilters(immediate: true);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchTitle = searchTitle;
                                _searchArtist = searchArtist;
                                _searchAlbum = searchAlbum;
                                _searchLyrics = searchLyrics;
                                _searchLanguage = searchLanguage;
                                _searchGenre = searchGenre;
                                _selectedLanguage = selectedLanguage;
                                _selectedGenre = selectedGenre;
                                _sort = sort;
                              });
                              _applyFilters(immediate: true);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.iconcolor2,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

  Widget _buildModalTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _labelize(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  int get _activeFilterCount {
    var count = 0;
    if (!_searchTitle) count++;
    if (!_searchArtist) count++;
    if (!_searchAlbum) count++;
    if (_searchLyrics) count++;
    if (!_searchLanguage) count++;
    if (!_searchGenre) count++;
    if (_selectedLanguage != null) count++;
    if (_selectedGenre != null) count++;
    if (_sort != _SearchSort.relevance) count++;
    return count;
  }

  List<String> get _selectedSearchAreas {
    final areas = <String>[];
    if (_searchTitle) areas.add('Title');
    if (_searchArtist) areas.add('Artist');
    if (_searchAlbum) areas.add('Album');
    if (_searchLyrics) areas.add('Lyrics');
    if (_searchLanguage) areas.add('Language');
    if (_searchGenre) areas.add('Genre');
    return areas;
  }

  String get _searchAreaSummary {
    final areas = _selectedSearchAreas;
    if (areas.isEmpty) return 'No fields';
    if (areas.length <= 2) return areas.join(', ');
    return '${areas.take(2).join(', ')} +${areas.length - 2}';
  }

  String get _sortLabel {
    switch (_sort) {
      case _SearchSort.relevance:
        return 'Relevance';
      case _SearchSort.titleAz:
        return 'Title A-Z';
      case _SearchSort.artistAz:
        return 'Artist A-Z';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final compact = ResponsiveUtils.isCompact(context);
    final playerProvider = Provider.of<SongPlayerProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              8,
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 14 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _controller,
                        onChanged: (_) => _applyFilters(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          icon: const Icon(Icons.search, color: Colors.white70),
                          hintText: 'Search songs, artists, albums, lyrics...',
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _controller.clear();
                                    _applyFilters(immediate: true);
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.tune_rounded,
                            label: _activeFilterCount == 0
                                ? 'Smart Search'
                                : '$_activeFilterCount filters active',
                            highlighted: _activeFilterCount > 0,
                            onTap: _openAdvancedSearchSheet,
                          ),
                          _InfoChip(
                            icon: Icons.manage_search_rounded,
                            label: 'In: $_searchAreaSummary',
                            highlighted: true,
                            onTap: _openAdvancedSearchSheet,
                          ),
                          if (_selectedLanguage != null)
                            _InfoChip(
                              icon: Icons.language_rounded,
                              label: _labelize(_selectedLanguage!),
                              highlighted: true,
                              onTap: _openAdvancedSearchSheet,
                            ),
                          if (_selectedGenre != null)
                            _InfoChip(
                              icon: Icons.graphic_eq_rounded,
                              label: _labelize(_selectedGenre!),
                              highlighted: true,
                              onTap: _openAdvancedSearchSheet,
                            ),
                          if (_sort != _SearchSort.relevance)
                            _InfoChip(
                              icon: Icons.sort_by_alpha_rounded,
                              label: _sortLabel,
                              highlighted: true,
                              onTap: _openAdvancedSearchSheet,
                            ),
                          if (_searchLyrics)
                            _InfoChip(
                              icon: Icons.lyrics_outlined,
                              label: 'Lyrics',
                              highlighted: true,
                              onTap: _openAdvancedSearchSheet,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openAdvancedSearchSheet,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLoading) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredSongs.length} results found',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          isLoading
              ? const Expanded(child: AppLoadingWidget())
              : filteredSongs.isEmpty
              ? Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 52,
                            color: Colors.white38,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No matching songs found',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Try a different keyword or open Advanced Search to refine the result.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      4,
                      horizontalPadding,
                      18,
                    ),
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      final album = _songField(song, const ['album', 'movie']);
                      final language = _songField(song, const [
                        'language',
                        'lang',
                        'category',
                      ]);

                      return InkWell(
                        onTap: () {
                          playerProvider.setPlaylist(filteredSongs);
                          playerProvider.playSong(song);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 6 : 8,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  song['album_art'] ?? '',
                                  width: compact ? 54 : 60,
                                  height: compact ? 54 : 60,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        width: compact ? 54 : 60,
                                        height: compact ? 54 : 60,
                                        color: Colors.white10,
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 38,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                              SizedBox(width: compact ? 12 : 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song['title'] ?? 'Unknown Title',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveUtils.responsiveFont(
                                          context,
                                          compact: 14,
                                          regular: 15,
                                          tablet: 16,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      song['artist'] ?? 'Unknown Artist',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: ResponsiveUtils.responsiveFont(
                                          context,
                                          compact: 12,
                                          regular: 13,
                                          tablet: 14,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (album.isNotEmpty || language.isNotEmpty) ...[
                                      const SizedBox(height: 7),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (album.isNotEmpty)
                                            _ResultMetaChip(label: album),
                                          if (language.isNotEmpty)
                                            _ResultMetaChip(
                                              label: _labelize(language),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert_outlined,
                                  color: Colors.white,
                                ),
                                onPressed: () => _showBottomDrawer(context, song),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  void _showBottomDrawer(BuildContext context, Map<String, dynamic> song) {
    showSongActionSheet(
      context: context,
      song: song,
      playlist: filteredSongs.isEmpty ? allSongs : filteredSongs,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: highlighted
              ? AppColors.iconcolor2.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: highlighted
                ? AppColors.iconcolor2.withOpacity(0.45)
                : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: highlighted ? AppColors.iconcolor2 : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.responsiveFont(
                  context,
                  compact: 11,
                  regular: 12,
                  tablet: 13,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterToggleChip extends StatelessWidget {
  const _FilterToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? AppColors.iconcolor2 : Colors.white.withOpacity(0.04),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.iconcolor2.withOpacity(0.95),
                    AppColors.iconcolor1.withOpacity(0.92),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
          border: Border.all(
            color:
                selected ? AppColors.iconcolor1.withOpacity(0.55) : Colors.white12,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: AppColors.iconcolor2.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.responsiveFont(
                  context,
                  compact: 12,
                  regular: 13,
                  tablet: 14,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetaChip extends StatelessWidget {
  const _ResultMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white70,
          fontSize: ResponsiveUtils.responsiveFont(
            context,
            compact: 10,
            regular: 11,
            tablet: 12,
          ),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
