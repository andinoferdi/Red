import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/player_controller.dart';
import '../../states/player_state.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helpers.dart';
import '../../utils/color_extractor.dart';
import '../../providers/dynamic_color_provider.dart';
import '../../routes/app_router.dart';

@RoutePage()
class MusicPlayerScreen extends ConsumerStatefulWidget {
  final Song? song;
  
  const MusicPlayerScreen({this.song, super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen> {
  Artist? _currentArtist;
  bool _isLoadingArtist = false;
  List<Song> _artistSongs = [];
  bool _isLoadingArtistSongs = false;
  late ArtistRepository _artistRepository;
  late SongRepository _songRepository;
  
  // Store the original song to keep Jelajahi Artist consistent
  Song? _originalSong;
  String? _originalArtistName;

  @override
  void initState() {
    super.initState();
    _artistRepository = ArtistRepository(PocketBaseService());
    _songRepository = SongRepository(PocketBaseService());
  }

  @override
  void didUpdateWidget(MusicPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If widget.song changes (user navigated to music player with different song)
    // reset the original song reference
    if (widget.song != null && 
        oldWidget.song?.id != widget.song?.id && 
        _originalSong?.id != widget.song?.id) {
      

      
      _originalSong = widget.song;
      _originalArtistName = widget.song?.artist;
      
      // Reload artist info and songs for new original song
      if (_originalArtistName != null) {
        _loadArtistInfo(_originalArtistName!);
        _loadArtistSongs(_originalArtistName!, _originalSong!.id);
      }
    }
  }

  Future<void> _loadArtistInfo(String artistName) async {
    if (_isLoadingArtist) return;
    
    setState(() {
      _isLoadingArtist = true;
    });

    try {
      final artist = await _artistRepository.getArtistByName(artistName);
      if (mounted) {
        setState(() {
          _currentArtist = artist;
          _isLoadingArtist = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingArtist = false;
        });
      }
      
    }
  }

  Future<void> _loadArtistSongs(String artistName, String currentSongId) async {
    if (_isLoadingArtistSongs) return;
    
    setState(() {
      _isLoadingArtistSongs = true;
      _artistSongs = []; // Clear previous songs
    });

    try {

      final songs = await _songRepository.getSongsByArtistName(
        artistName, 
        excludeSongId: currentSongId,
      );
      if (mounted) {
        setState(() {
          _artistSongs = songs;
          _isLoadingArtistSongs = false;
        });

      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingArtistSongs = false;
        });
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final currentSong = playerState.currentSong ?? widget.song;
    
    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'No song is currently playing',
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    // Note: Removed automatic playback initiation to prevent interference with existing playback
    // The music player screen should only display current state, not start new playbook

    // Initialize original song on first load
    if (_originalSong == null) {
      // Prioritize widget.song if available, otherwise use currentSong
      _originalSong = widget.song ?? currentSong;
      _originalArtistName = _originalSong?.artist;
      

      
      // Load artist info and songs based on original song
      if (_originalArtistName != null) {
        _loadArtistInfo(_originalArtistName!);
        _loadArtistSongs(_originalArtistName!, _originalSong!.id);
      }
    }
    
    // Extract dynamic colors from current song's album art
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentSong != null) {
        ref.read(dynamicColorProvider.notifier).extractColorsFromSong(currentSong);
      }
    });
    
    // Update artist info for "Tentang artis" section based on current song
    // but keep Jelajahi Artist section based on original song
    if (_currentArtist?.name != currentSong.artist) {
      _loadArtistInfo(currentSong.artist);
      // Don't reload artist songs - keep them based on original song
    }

    // Get dynamic colors
    final colors = dynamicColorState.colors ?? ColorExtractor.getDefaultColors();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundStart,
              colors.backgroundStart.withValues(alpha: 0.7),
              const Color(0xFF1A1A1A).withValues(alpha: 0.8),
              const Color(0xFF000000), // Fade to pure black like Spotify
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Scrollable Content - Full height dengan padding atas untuk header
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 60, // Space for fixed header
                left: 20.0,
                right: 20.0,
                bottom: 20.0,
              ),
              child: Column(
                children: [
                    // Album Art
                    Container(
                      height: 280,
                      width: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.greyDark, // Background color for fallback
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Album art image with enhanced error handling
                            ImageHelpers.buildSafeNetworkImage(
                              imageUrl: currentSong.albumArtUrl,
                              width: 280,
                              height: 280,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(20),
                              showLoadingIndicator: true,
                              fallbackWidget: _buildFallbackAlbumArt(),
                            ),
                            
                            // Show loading indicator when buffering
                            if (playerState.isBuffering)
                              Container(
                                height: 280,
                                width: 280,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Song info
                    Column(
                      children: [
                        Text(
                          currentSong.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentSong.artist,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 18,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Playback controls
                    Column(
                      children: [
                        // Slider
                        Slider(
                          value: playerState.currentPosition.inSeconds.toDouble(),
                          max: currentSong.duration.inSeconds.toDouble(),
                          activeColor: Colors.white,
                          inactiveColor: colors.textSecondary.withValues(alpha: 0.3),
                          onChanged: (value) {
                            ref.read(playerControllerProvider.notifier).seekTo(
                              Duration(seconds: value.toInt()),
                            );
                          },
                        ),
                        
                        // Time indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(playerState.currentPosition),
                                style: TextStyle(color: colors.textSecondary),
                              ),
                              Text(
                                _formatDuration(currentSong.duration),
                                style: TextStyle(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Always show shuffle button - supports both playlist and general shuffle
                            IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                ref.read(playerControllerProvider.notifier).toggleShuffle();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                                size: 36,
                              ),
                              onPressed: () async {
                                try {
                                  await ref.read(playerControllerProvider.notifier).skipPrevious();
                                } catch (e) {
                              
                                }
                              },
                            ),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  playerState.isBuffering
                                      ? Icons.hourglass_empty
                                      : playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 36,
                                ),
                                onPressed: () {
                                  if (playerState.isBuffering) {
                                    // Do nothing while buffering
                                    return;
                                  }
                                  
                                  if (playerState.isPlaying) {
                                    ref.read(playerControllerProvider.notifier).pause();
                                  } else {
                                    ref.read(playerControllerProvider.notifier).resume();
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.skip_next,
                                color: Colors.white,
                                size: 36,
                              ),
                              onPressed: () async {
                                try {
                                  await ref.read(playerControllerProvider.notifier).skipNext();
                                } catch (e) {
                              
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                playerState.repeatMode == RepeatMode.off
                                    ? Icons.repeat
                                    : playerState.repeatMode == RepeatMode.one
                                        ? Icons.repeat_one
                                        : Icons.repeat,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                ref.read(playerControllerProvider.notifier).toggleRepeatMode();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // About Artist Section (Spotify-style) - Above lyrics
                    _buildAboutArtistSection(currentSong),
                    
                    // Lyrics Preview Section (Spotify-style)
                    _buildLyricsPreviewSection(currentSong),
                    
                    // Jelajahi Artist Section (Spotify Shorts-style) - based on original song
                    if (_originalSong != null && _originalArtistName != null)
                      _buildJelajahiArtistSection(_originalSong!),
                ],
              ),
            ),
            
            // Fixed Header - Positioned overlay yang benar-benar fixed
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8, // Status bar padding
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.backgroundStart,
                      colors.backgroundStart.withValues(alpha: 0.9),
                      colors.backgroundStart.withValues(alpha: 0.7),
                      colors.backgroundStart.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.6, 0.8, 1.0],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      onPressed: () => context.router.maybePop(),
                    ),
                    const Text(
                      'Now Playing',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLyricsPreviewSection(Song currentSong) {
    final hasLyrics = currentSong.lyrics != null && currentSong.lyrics!.trim().isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lyrics preview container (Spotify-style)
        GestureDetector(
          onTap: () {
            // Navigate to full-screen lyrics
            context.router.push(LyricsRoute(song: currentSong));
          },
          child: hasLyrics 
              ? _buildLyricsPreview(currentSong)
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greyDark.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildNoLyricsPreview(),
                ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }
  
  Widget _buildLyricsPreview(Song song) {
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final colors = dynamicColorState.colors ?? ColorExtractor.getDefaultColors();
    
    // Get first few lines of lyrics for preview
    final lyricsLines = song.lyrics!.split('\n');
    final previewLines = lyricsLines.take(3).where((line) => line.trim().isNotEmpty).toList();
    final previewText = previewLines.join('\n');
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primary, // Keep solid color for lyrics readability
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // "Lyrics" text overlay
          const Positioned(
            top: 16,
            left: 20,
            child: Text(
              'Lyrics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          
          // Content with padding
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20), // Top padding for "Lyrics" text
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview text with smooth Spotify-style fade-out
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.white,
                        Color(0x88FFFFFF), // Semi-transparent
                        Color(0x44FFFFFF), // More transparent
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.65, 0.8, 0.9, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Text(
                    previewText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.clip,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Show more button with white background
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tampilkan Lirik',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: colors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoLyricsPreview() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 24,
              color: AppColors.greyLight,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No lyrics available for this song',
                style: TextStyle(
                  color: AppColors.greyLight,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // View anyway button
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.greyLight,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAboutArtistSection(Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Artist info container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A), // Solid grey background
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isLoadingArtist
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildLoadingArtistState(),
                )
              : _currentArtist != null
                  ? _buildArtistContent(_currentArtist!, currentSong)
                  : _buildFallbackArtistContent(currentSong),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildLoadingArtistState() {
    return const Column(
      children: [
        SizedBox(height: 20),
        CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
        SizedBox(height: 16),
        Text(
          'Loading artist info...',
          style: TextStyle(
            color: AppColors.greyLight,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildArtistContent(Artist artist, Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width artist image with overlay text (Spotify-style)
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            color: AppColors.greyDark,
          ),
          child: Stack(
            children: [
              // Artist image filling entire container
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: artist.imageUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    color: AppColors.greyDark,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 60,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No Artist Image',
                          style: TextStyle(
                            color: AppColors.greyLight,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              
              // "Tentang artis" text overlay
              const Positioned(
                top: 16,
                left: 16,
                child: Text(
                  'Tentang artis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Artist info below image
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '9,3 jt pendengar bulanan', // Static for now
                          style: const TextStyle(
                            color: AppColors.greyLight,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Follow button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.greyLight,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ikuti',
                      style: TextStyle(
                        color: AppColors.greyLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Artist bio from PocketBase
              Text(
                artist.bio.isNotEmpty ? artist.bio : 'No biography available for this artist.',
                style: const TextStyle(
                  color: AppColors.greyLight,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Poppins',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // "lihat semua" text
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to artist detail page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artist detail page coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: const Text(
                  'lihat semua',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFallbackArtistContent(Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width fallback image with overlay text
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            color: AppColors.greyDark,
          ),
          child: Stack(
            children: [
              // Fallback content
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 60,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Artist Image',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              
              // "Tentang artis" text overlay
              const Positioned(
                top: 16,
                left: 16,
                child: Text(
                  'Tentang artis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Artist info below image
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.artist,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Artist information not available',
                          style: TextStyle(
                            color: AppColors.greyLight,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Fallback message
              const Text(
                'Artist information is not available in the database yet. Check back later for more details about this artist.',
                style: TextStyle(
                  color: AppColors.greyLight,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Poppins',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildJelajahiArtistSection(Song currentSong) {
    // Use original artist name for consistent Jelajahi Artist section
    final displayArtistName = _originalArtistName ?? currentSong.artist;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Text(
                'Jelajahi ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                displayArtistName,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Horizontal scrollable song list
        SizedBox(
          height: 200, // Fixed height for horizontal scroll
          child: _isLoadingArtistSongs
              ? _buildLoadingArtistSongs()
              : _artistSongs.isEmpty
                  ? _buildEmptyArtistSongs(displayArtistName)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: _artistSongs.length,
                      itemBuilder: (context, index) {
                        final song = _artistSongs[index];
                        return _buildArtistSongCard(song, index == 0, index == _artistSongs.length - 1);
                      },
                    ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }
  
  Widget _buildLoadingArtistSongs() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: 5, // Show 5 loading placeholders
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 8,
            right: index == 4 ? 0 : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album art placeholder
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Title placeholder
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Artist placeholder
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.greyDark.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyArtistSongs(String artistName) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greyDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.music_note_outlined,
                size: 32,
                color: AppColors.greyLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada lagu lain dari',
              style: const TextStyle(
                color: AppColors.greyLight,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              artistName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Coba lagi nanti untuk melihat lebih banyak lagu',
              style: TextStyle(
                color: AppColors.greyLight,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildArtistSongCard(Song song, bool isFirst, bool isLast) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    
    return GestureDetector(
      onTap: () {
        if (isCurrentSong) {
          // If this is the current song, toggle play/pause
          if (playerState.isPlaying) {
            ref.read(playerControllerProvider.notifier).pause();
          } else {
            ref.read(playerControllerProvider.notifier).resume();
          }
        } else {
          // Play the selected song but don't update the original song reference
          // This keeps the Jelajahi Artist section consistent
          ref.read(playerControllerProvider.notifier).playSong(song);
        }
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.only(
          left: isFirst ? 0 : 8,
          right: isLast ? 0 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art with play indicator
            Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.greyDark,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageHelpers.buildSafeNetworkImage(
                      imageUrl: song.albumArtUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      showLoadingIndicator: true,
                      fallbackWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.greyDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.music_note,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrentSong && playerState.isPlaying 
                              ? AppColors.primary.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentSong && playerState.isPlaying 
                              ? Icons.pause 
                              : Icons.play_arrow,
                          color: isCurrentSong && playerState.isPlaying 
                              ? Colors.white 
                              : Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Current song indicator
                if (isCurrentSong)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Song title
            Text(
              song.title,
              style: TextStyle(
                color: isCurrentSong ? AppColors.primary : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2),
            
            // Duration
            Text(
              _formatDuration(song.duration),
              style: const TextStyle(
                color: AppColors.greyLight,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build fallback album art when image fails to load
  Widget _buildFallbackAlbumArt() {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.greyDark,
            AppColors.background,
          ],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'No Album Art',
            style: TextStyle(
              color: AppColors.greyLight,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
