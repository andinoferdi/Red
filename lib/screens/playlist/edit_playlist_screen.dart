import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/app_colors.dart';
import '../../models/song.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/song_playlist_repository.dart';
import '../../widgets/song_item_widget.dart';
// Removed player controller and mini player imports for edit playlist screen
import '../../widgets/playlist_image_widget.dart';
import 'add_songs_screen.dart';
import '../../providers/playlist_provider.dart';
import '../../routes/app_router.dart';

@RoutePage()
class EditPlaylistScreen extends ConsumerStatefulWidget {
  final RecordModel playlist;

  const EditPlaylistScreen({
    super.key,
    required this.playlist,
  });

  @override
  ConsumerState<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends ConsumerState<EditPlaylistScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isSaving = false;
  List<Song> _songs = [];
  List<Song> _originalSongs = [];
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isPublic = false;
  bool _isEditingDescription = false;
  
  // Original values for change detection
  String _originalName = '';
  String _originalDescription = '';
  bool _originalIsPublic = false;
  String? _originalImageUrl;
  
  // Track removed songs (only remove from database when saving)
  final Set<String> _removedSongIds = {};
  final Map<String, int> _originalSongOrder = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    
    // Initialize global playlist state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistProvider.notifier).loadPlaylists();
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Initialize playlist data
      _originalName = widget.playlist.data['name'] ?? '';
      _originalDescription = widget.playlist.data['description'] ?? '';
      _originalIsPublic = widget.playlist.data['is_public'] ?? false;
      
      _nameController.text = _originalName;
      _descriptionController.text = _originalDescription;
      _isPublic = _originalIsPublic;
      
      // Get current image URL if exists
      final coverImage = widget.playlist.data['cover_image'] as String?;
      if (coverImage != null && coverImage.trim().isNotEmpty) {
        try {
          final pbService = PocketBaseService();
          _currentImageUrl = pbService.pb.files.getUrl(widget.playlist, coverImage).toString();
          _originalImageUrl = _currentImageUrl;
  
        } catch (e) {
          _currentImageUrl = null;
          _originalImageUrl = null;
        }
      }

      // Load playlist songs
      await _loadPlaylistSongs();
      
      // Listen to text changes for change detection
      _nameController.addListener(_onTextChanged);
      _descriptionController.addListener(_onTextChanged);
    } catch (e) {
      _showErrorMessage('Gagal memuat data playlist: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlaylistSongs() async {
    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final songPlaylistRepo = SongPlaylistRepository(pbService);
      final songs = await songPlaylistRepo.getPlaylistSongs(widget.playlist.id);
      
      setState(() {
        _songs = songs;
        _originalSongs = List.from(songs); // Keep original order
        
        // Store original song order for change detection
        _originalSongOrder.clear();
        for (int i = 0; i < songs.length; i++) {
          _originalSongOrder[songs[i].id] = i;
        }
      });
    } catch (e) {
      _showErrorMessage('Gagal memuat lagu playlist: ${e.toString()}');
    }
  }

  void _onTextChanged() {
    setState(() {
      // This will trigger a rebuild and update save button state
    });
  }

  bool get _hasChanges {
    // Check if name changed
    if (_nameController.text.trim() != _originalName) return true;
    
    // Check if description changed
    if (_descriptionController.text.trim() != _originalDescription) return true;
    
    // Check if currently editing description (unsaved changes)
    if (_isEditingDescription) return true;
    
    // Check if public status changed
    if (_isPublic != _originalIsPublic) return true;
    
    // Check if image changed
    if (_selectedImage != null) return true;
    if (_currentImageUrl != _originalImageUrl) return true;
    
    // Check if songs were removed
    if (_removedSongIds.isNotEmpty) return true;
    
    // Check if songs order changed
    if (_songs.length != _originalSongs.length) return true;
    for (int i = 0; i < _songs.length; i++) {
      if (_songs[i].id != _originalSongs[i].id) return true;
    }
    
    return false;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorMessage('Gagal memilih gambar: ${e.toString()}');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
    });
  }

  Future<void> _savePlaylist() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorMessage('Nama playlist tidak boleh kosong');
      return;
    }

    // Save description if currently editing
    if (_isEditingDescription) {
      _saveDescription();
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final repository = PlaylistRepository(pbService);
      final songPlaylistRepo = SongPlaylistRepository(pbService);

      // 1. Update playlist basic info
      await repository.updatePlaylist(
        playlistId: widget.playlist.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        coverImageFile: _selectedImage,
      );
      
      // 2. Remove songs that were marked for removal
      for (final songId in _removedSongIds) {
        try {
          await songPlaylistRepo.removeSongFromPlaylist(widget.playlist.id, songId);
        } catch (e) {
  
          // Continue with other removals even if one fails
        }
      }
      
      // 3. Update song order if changed
      await _saveFinalSongOrder();
      
      // Clear playlist image cache for this specific playlist
      PlaylistImageWidget.clearCache(widget.playlist.id);
      
      // Notify global playlist provider about update
      ref.read(playlistProvider.notifier).notifyPlaylistModified(widget.playlist.id);
      
      _showSuccessMessage('Playlist berhasil diperbarui!');
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate changes were made
      }
    } catch (e) {
      _showErrorMessage('Gagal menyimpan playlist: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    // Show confirmation dialog
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Hapus dari Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Hapus "${song.title}" dari playlist ini?\n\nPerubahan akan disimpan saat menekan tombol Simpan.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batalkan'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      // Only remove from UI and mark for removal - don't save to database yet
      setState(() {
        _songs.removeWhere((s) => s.id == song.id);
        _removedSongIds.add(song.id); // Mark for removal when saving
      });
      
      _showSuccessMessage('Lagu akan dihapus saat menyimpan playlist');
    }
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Song item = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, item);
    });
    
    // TODO: Save new order to backend
    _saveNewOrder();
  }

  Future<void> _saveNewOrder() async {
    // Don't save immediately - just show message that changes will be saved
    _showSuccessMessage('Urutan lagu akan disimpan saat menyimpan playlist');
  }
  
  Future<void> _saveFinalSongOrder() async {
    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final songPlaylistRepo = SongPlaylistRepository(pbService);
      
      // Update order in backend
      for (int i = 0; i < _songs.length; i++) {
        await songPlaylistRepo.updateSongOrder(
          widget.playlist.id, 
          _songs[i].id, 
          i + 1
        );
      }
          } catch (e) {

        rethrow; // Re-throw to be handled by _savePlaylist
      }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onBackPressed() {
    if (_hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Perubahan Belum Disimpan',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batalkan'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close edit screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar Tanpa Menyimpan'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _savePlaylist(); // Save and exit
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Simpan & Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch auto-refresh playlist provider for automatic updates
    ref.watch(autoRefreshPlaylistProvider);
    
    // Auto-refresh when global playlist state changes
    ref.listen(playlistProvider, (previous, next) {
      if (previous?.lastUpdated != next.lastUpdated && !_isLoading) {

        _loadPlaylistSongs();
      }
    });
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildPlaylistInfo(),
                    // Move description section up too
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Column(
                        children: [
                          _buildDescriptionSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSongsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      expandedHeight: 300,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _onBackPressed,
      ),
      title: const Text(
        'Edit Playlist',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_isSaving || !_hasChanges) ? null : _savePlaylist,
          child: _isSaving 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Simpan',
                style: TextStyle(
                  color: _hasChanges ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[900]!,
                    AppColors.background,
                  ],
                ),
              ),
            ),
            // Image section
            Positioned(
              left: 0,
              right: 0,
              top: 100,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: _buildEditablePlaylistImage(),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedImage != null || _currentImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: _removeImage,
                        child: const Text(
                          'Ganti gambar',
                          style: TextStyle(color: Colors.white70),
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

  Widget _buildEditablePlaylistImage() {
    // If user has selected a new image, show it
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    
    // Otherwise, use the unified playlist image widget
    return PlaylistImageWidget(
      playlist: widget.playlist,
      size: 200,
      borderRadius: 4,
      showMosaicForEmptyPlaylists: true,
    );
  }

  Widget _buildPlaylistInfo() {
    return Column(
      children: [
        // Playlist name field - completely transparent, no container
        IntrinsicWidth(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Nama Playlist',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  contentPadding: EdgeInsets.only(bottom: -5),
                  isDense: true,
                ),
                maxLines: 2,
                cursorColor: Colors.white,
              ),
              // Spotify-style underline - moved closer to text
              Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Negative margin to compensate for transform offset
        Transform.translate(
          offset: const Offset(0, -30),
          child: Text(
            '${_songs.length} lagu',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      children: [
        // Show button or current description
        if (!_isEditingDescription && _descriptionController.text.isEmpty)
          _buildDescriptionButton()
        else if (!_isEditingDescription && _descriptionController.text.isNotEmpty)
          _buildExistingDescription()
        else
          _buildDescriptionInput(),
        
        // Help text - only show when not editing or when field is empty
        if (!_isEditingDescription)
          Column(
            children: [
              const SizedBox(height: 2),
            ],
          ),
      ],
    );
  }

  Widget _buildDescriptionButton() {
    return OutlinedButton(
      onPressed: _startEditingDescription,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text(
        'Tambahkan deskripsi',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildExistingDescription() {
    return GestureDetector(
      onTap: _startEditingDescription,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _descriptionController.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ketuk untuk mengedit',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _descriptionController,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Tambahkan deskripsi playlist...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 3,
            cursorColor: Colors.white,
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelEditingDescription,
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _saveDescription,
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startEditingDescription() {
    setState(() {
      _isEditingDescription = true;
    });
  }

  void _saveDescription() {
    setState(() {
      _isEditingDescription = false;
    });
  }

  void _cancelEditingDescription() {
    setState(() {
      // Reset to original description
      _descriptionController.text = _originalDescription;
      _isEditingDescription = false;
    });
  }

  Widget _buildSongsSection() {
    if (_songs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _reorderSongs,
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            final song = _songs[index];
            return _buildDraggableSongItem(song, index);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 50),
        const Text(
          'Mulai menambahkan ke playlist kamu.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Kamu bisa mengeditnya di sini.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Navigate to add songs screen
            Navigator.push(
              context,
              AppRouter.createConsistentRoute(
                AddSongsScreen(playlist: widget.playlist),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Cari lagu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableSongItem(Song song, int index) {
    return Container(
      key: ValueKey(song.id),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Remove button
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.red,
              size: 24,
            ),
            onPressed: () => _removeSongFromPlaylist(song),
          ),
          // Song info
          Expanded(
            child: SongItemWidget(
              song: song,
              subtitle: song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
              isDisabled: true, // Completely disable tap functionality in edit mode
            ),
          ),
          // Drag handle with proper listener
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.drag_handle,
                color: Colors.white54,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

