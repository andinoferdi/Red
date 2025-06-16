import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../utils/app_colors.dart';
import '../../models/song.dart';

import '../../controllers/player_controller.dart';
import '../../providers/song_provider.dart';

import '../../widgets/mini_player.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/song_item_widget.dart';
import '../../widgets/animated_sound_bars.dart';


@RoutePage()
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Song> _searchResults = [];
  List<Song> _recentSearchedSongs = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecentSearchedSongs();
    _searchFocusNode.requestFocus();
    
    // Load songs using new provider
    Future.microtask(() {
      ref.read(songProvider.notifier).loadSongs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearchedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = prefs.getStringList('recent_searched_songs') ?? [];
    final songs = songsJson.map((jsonStr) {
      try {
        final Map<String, dynamic> songMap = Map<String, dynamic>.from(jsonDecode(jsonStr));
        return Song.fromJson(songMap);
      } catch (e) {
        return null;
      }
    }).where((song) => song != null).cast<Song>().toList();
    
    setState(() {
      _recentSearchedSongs = songs;
    });
  }

  Future<void> _saveRecentSearchedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = _recentSearchedSongs.map((song) => jsonEncode(song.toJson())).toList();
    await prefs.setStringList('recent_searched_songs', songsJson);
  }

  Future<void> _addToRecentSearchedSongs(Song song) async {
    // Remove if already exists to avoid duplicates
    _recentSearchedSongs.removeWhere((s) => s.id == song.id);
    
    // Add to beginning of list
    _recentSearchedSongs.insert(0, song);
    
    // Keep only last 20 songs
    if (_recentSearchedSongs.length > 20) {
      _recentSearchedSongs = _recentSearchedSongs.take(20).toList();
    }
    
    await _saveRecentSearchedSongs();
    setState(() {});
  }

  Future<void> _removeFromRecentSearchedSongs(Song song) async {
    _recentSearchedSongs.removeWhere((s) => s.id == song.id);
    await _saveRecentSearchedSongs();
    setState(() {});
  }

  Future<void> _clearAllRecentSearchedSongs() async {
    _recentSearchedSongs.clear();
    await _saveRecentSearchedSongs();
    setState(() {});
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      // Use new song provider for local search (much faster)
      final songController = ref.read(songProvider.notifier);
      final searchResults = songController.searchSongs(query);

      setState(() {
        _searchResults = searchResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search: $e';
        _isLoading = false;
      });
    }
  }

  void _playSong(Song song, int index) {
    // Add song to recent searched songs when played from search results
    _addToRecentSearchedSongs(song);
    // Use playSongById to load complete song data without playlist context (like home screen)
    ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
    
    // Color extraction will be handled automatically by mini_player when song changes
  }

  void _playSongFromRecent(Song song) {
    // Use playSongById to load complete song data without playlist context (like home screen)
    ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
    
    // Color extraction will be handled automatically by mini_player when song changes
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _buildSearchContent(),
          ),
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Explore tab index
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSearchHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.router.maybePop(),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari lagu, artis, atau album',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _hasSearched = false;
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    } else {
                      setState(() {
                        _searchResults = [];
                        _hasSearched = false;
                      });
                    }
                  },
                  onSubmitted: _performSearch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_hasSearched) {
      return _buildSearchResults();
    }

    return _buildRecentSearchedSongs();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Terjadi kesalahan',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        return _buildSongItem(song, index);
      },
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci yang berbeda',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchedSongs() {
    if (_recentSearchedSongs.isEmpty) {
      return _buildEmptyHistory();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pencarian terkini',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearAllRecentSearchedSongs,
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearchedSongs.length,
            itemBuilder: (context, index) {
              final song = _recentSearchedSongs[index];
              return _buildRecentSongItem(song);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Kamu belum mencari apapun',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai cari lagu, artis, atau album favoritmu',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSongItem(Song song) {
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(playerControllerProvider);
        final isCurrentSong = playerState.currentSong?.id == song.id;
        final isPlaying = isCurrentSong && playerState.isPlaying;
        
        return SongItemWidget(
          song: song,
          subtitle: song.artist,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show animated sound bars when playing (same as default SongItemWidget)
              if (isPlaying)
                const AnimatedSoundBars(
                  color: Colors.red,
                  size: 20.0,
                  isAnimating: true,
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => _removeFromRecentSearchedSongs(song),
              ),
            ],
          ),
          onTap: () => _playSongFromRecent(song),
        );
      },
    );
  }

  Widget _buildSongItem(Song song, int index) {
    return SongItemWidget(
      song: song,
      subtitle: song.artist,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      onTap: () => _playSong(song, index),
    );
  }
} 

