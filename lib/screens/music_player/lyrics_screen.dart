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
      backgroundColor: colors.backgroundStart,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar with solid color
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.keyboard_arrow_down, color: colors.textPrimary, size: 28),
              onPressed: () => context.router.maybePop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: colors.textPrimary),
                onPressed: () {
                  // TODO: Implement share lyrics functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Share lyrics feature coming soon!'),
                      backgroundColor: colors.accent,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: colors.textPrimary),
                onPressed: () {
                  // TODO: Implement more options
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: colors.primary.withValues(alpha: 0.8),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Small album art
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ImageHelpers.buildSafeNetworkImage(
                                  imageUrl: currentSong.albumArtUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  fallbackWidget: Container(
                                    color: AppColors.greyDark,
                                    child: Icon(
                                      Icons.music_note,
                                      color: colors.accent,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Song info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.title,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentSong.artist,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Lyrics content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildLyricsContent(currentSong),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLyricsContent(Song song) {
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final colors = dynamicColorState.colors ?? ColorExtractor.getDefaultColors();
    
    if (song.lyrics == null || song.lyrics!.trim().isEmpty) {
      return _buildNoLyricsState(song);
    }
    
    // Split lyrics into lines for better formatting
    final lyricsLines = song.lyrics!.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lyrics header
        Row(
          children: [
            Icon(
              Icons.lyrics,
              color: colors.accent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Lyrics',
              style: TextStyle(
                color: colors.accent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            // Font size controls
            IconButton(
              icon: Icon(Icons.text_decrease, color: colors.textSecondary),
              onPressed: () {
                // TODO: Implement font size decrease
              },
            ),
            IconButton(
              icon: Icon(Icons.text_increase, color: colors.textSecondary),
              onPressed: () {
                // TODO: Implement font size increase
              },
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Lyrics text with solid background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lyricsLines.map((line) {
              final trimmedLine = line.trim();
              
              // Empty line for spacing
              if (trimmedLine.isEmpty) {
                return const SizedBox(height: 12);
              }
              
              // Check if it's a chorus or special section (contains brackets)
              final isSpecialSection = trimmedLine.contains('[') && trimmedLine.contains(']');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  trimmedLine,
                  style: TextStyle(
                    color: isSpecialSection ? Colors.white : Colors.white,
                    fontSize: isSpecialSection ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                    fontFamily: 'Poppins',
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Song info footer
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '♪ ${song.title} - ${song.artist} ♪',
              style: const TextStyle(
                color: AppColors.greyLight,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }
  
  Widget _buildNoLyricsState(Song song) {
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final colors = dynamicColorState.colors ?? ColorExtractor.getDefaultColors();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          
          // Large music note icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.backgroundEnd.withValues(alpha: 0.3),
            ),
            child: Icon(
              Icons.lyrics_outlined,
              size: 60,
              color: colors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'No lyrics available',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Lyrics for "${song.title}" are not available yet.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Check back later or try another song.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Suggest action button
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement suggest lyrics or report missing lyrics
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Suggest lyrics feature coming soon!'),
                  backgroundColor: colors.accent,
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Suggest Lyrics',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }
} 