import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/player_controller.dart';
import '../../models/song.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helpers.dart';
import '../../utils/color_extractor.dart';
import '../../providers/dynamic_color_provider.dart';

@RoutePage()
class LyricsScreen extends ConsumerStatefulWidget {
  final Song song;
  
  const LyricsScreen({
    super.key,
    required this.song,
  });

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final currentSong = playerState.currentSong ?? widget.song;
    final colors = dynamicColorState.colors ?? ColorExtractor.getDefaultColors();
    
    // Extract colors from current song if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentSong != null) {
        ref.read(dynamicColorProvider.notifier).extractColorsFromSong(currentSong);
      }
    });
    
    return Scaffold(
      backgroundColor: colors.primary, // Static background color from palette
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with navigation and song info in one row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
              onPressed: () => context.router.maybePop(),
            ),
                  
                  // Song title and artist in the center
                  Expanded(
                    child: Column(
                                children: [
                                  Text(
                                    currentSong.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'DM Sans',
                                    ),
                          textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        const SizedBox(height: 2),
                                  Text(
                                    currentSong.artist,
                                    style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                                      fontFamily: 'DM Sans',
                                    ),
                          textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                  
                  // More options button
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {
                      // TODO: Implement more options
                    },
                ),
                ],
            ),
          ),
          
            // Lyrics content - takes most of the space with fade effect
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: _buildLyricsContent(currentSong),
                    ),
                  ),
                  // Fade effect at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.primary.withValues(alpha: 0.0),
                            colors.primary.withValues(alpha: 0.6),
                            colors.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: playerState.currentPosition.inSeconds.toDouble(),
                      max: (currentSong.duration.inSeconds > 0 
                          ? currentSong.duration.inSeconds 
                          : 1).toDouble(),
                      onChanged: (value) {
                        ref.read(playerControllerProvider.notifier)
                            .seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  
                  // Time labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerState.currentPosition),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        Text(
                          _formatDuration(currentSong.duration),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Play/Pause button
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: colors.primary,
                        size: 32,
                      ),
                      onPressed: () {
                        if (playerState.isPlaying) {
                          ref.read(playerControllerProvider.notifier).pause();
                        } else {
                          ref.read(playerControllerProvider.notifier).resume();
                        }
                      },
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
  
  Widget _buildLyricsContent(Song song) {
    if (song.lyrics == null || song.lyrics!.trim().isEmpty) {
      return _buildNoLyricsState();
    }
    
    // Split lyrics into lines for better formatting
    final lyricsLines = song.lyrics!.split('\n');
    
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 80), // Extra bottom padding for scrolling
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lyricsLines.map((line) {
              final trimmedLine = line.trim();
              
              // Empty line for spacing
              if (trimmedLine.isEmpty) {
            return const SizedBox(height: 20);
              }
              
              // Check if it's a chorus or special section (contains brackets)
              final isSpecialSection = trimmedLine.contains('[') && trimmedLine.contains(']');
              
              return Padding(
            padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  trimmedLine,
                  style: TextStyle(
                color: isSpecialSection 
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white,
                fontSize: isSpecialSection ? 13 : 18,
                fontWeight: isSpecialSection ? FontWeight.w500 : FontWeight.w600,
                height: 1.4,
                fontFamily: 'DM Sans',
              ),
              textAlign: TextAlign.left,
            ),
          );
        }).toList(),
        ),
    );
  }
  
  Widget _buildNoLyricsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(
              Icons.lyrics_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'No lyrics available',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'DM Sans',
              ),
              textAlign: TextAlign.center,
              ),
          ],
          ),
      ),
    );
  }
} 

