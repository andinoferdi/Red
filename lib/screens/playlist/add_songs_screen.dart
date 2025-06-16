import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../models/song.dart';

import '../../repositories/song_playlist_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/song_item_widget.dart';
import '../../providers/song_provider.dart';

class AddSongsScreen extends ConsumerStatefulWidget {
  final RecordModel playlist;

  const AddSongsScreen({super.key, required this.playlist});

  @override
  ConsumerState<AddSongsScreen> createState() => _AddSongsScreenState();
}

class _AddSongsScreenState extends ConsumerState<AddSongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];

  final Set<String> _selectedSongIds = {};
  final Set<String> _existingSongIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Load songs using provider after widget is built
    Future.microtask(() {
      _loadSongs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load songs using provider
      final songState = ref.read(songProvider);
      List<Song> songs;
      
      if (songState.songs.isNotEmpty && !songState.isLoading) {
        // Use cached songs from provider
        songs = songState.songs;
      } else {
        // Load songs if not available
        await ref.read(songProvider.notifier).loadSongs();
        final updatedState = ref.read(songProvider);
        songs = updatedState.songs;
      }
      
      // Load existing playlist songs
      final pbService = PocketBaseService();
      await pbService.initialize();
      final songPlaylistRepository = SongPlaylistRepository(pbService);
      final playlistSongs = await songPlaylistRepository.getPlaylistSongs(widget.playlist.id);
      
      if (mounted) {
        setState(() {
          _allSongs = songs;
          _filteredSongs = songs;
          _existingSongIds.clear();
          _existingSongIds.addAll(playlistSongs.map((song) => song.id));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat lagu: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSongs = _allSongs;
      });
      return;
    }

    // Use song provider's search functionality for consistency
    final songController = ref.read(songProvider.notifier);
    final searchResults = songController.searchSongs(query);
    
    setState(() {
      _filteredSongs = searchResults;
    });
  }

  Future<void> _addSelectedSongs() async {
    if (_selectedSongIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pbService = PocketBaseService();
      final songPlaylistRepository = SongPlaylistRepository(pbService);

      // Use the new batch method for better performance and proper ordering
      final songIdsList = _selectedSongIds.toList();
      await songPlaylistRepository.addMultipleSongsToPlaylist(
            widget.playlist.id,
        songIdsList,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${songIdsList.length} lagu berhasil ditambahkan',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.white,
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan lagu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Tambah Lagu ke ${widget.playlist.data['name']}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedSongIds.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _addSelectedSongs,
              child: Text(
                'Tambah (${_selectedSongIds.length})',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSongs,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari lagu atau artis...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Songs List
          Expanded(
            child: _buildSongsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_isLoading && _allSongs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSongs,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                  ? 'Tidak ada lagu tersedia'
                  : 'Tidak ditemukan lagu yang cocok',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        final isSelected = _selectedSongIds.contains(song.id);
        final isInPlaylist = _existingSongIds.contains(song.id);
        
        return _buildSongItem(song, isSelected, isInPlaylist);
      },
    );
  }

  Widget _buildSongItem(Song song, bool isSelected, bool isInPlaylist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isInPlaylist 
            ? Colors.green.withValues(alpha: 0.1)
            : isSelected 
                ? Colors.red.withValues(alpha: 0.1) 
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isInPlaylist
            ? Border.all(color: Colors.green.withValues(alpha: 0.3))
            : isSelected 
                ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                : null,
      ),
      child: Opacity(
        opacity: isInPlaylist ? 0.6 : 1.0,
        child: SongItemWidget(
          song: song,
          subtitle: isInPlaylist 
              ? '${song.artist} • Sudah ditambahkan'
              : song.artist,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          trailing: Checkbox(
            value: isInPlaylist ? true : isSelected,
            onChanged: isInPlaylist ? null : (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedSongIds.add(song.id);
                } else {
                  _selectedSongIds.remove(song.id);
                }
              });
            },
            activeColor: isInPlaylist ? Colors.green : Colors.red,
            checkColor: Colors.white,
          ),
          onTap: isInPlaylist ? null : () {
            setState(() {
              if (isSelected) {
                _selectedSongIds.remove(song.id);
              } else {
                _selectedSongIds.add(song.id);
              }
            });
          },
        ),
      ),
    );
  }
} 

