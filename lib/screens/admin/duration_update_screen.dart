import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../../controllers/duration_controller.dart';
import '../../controllers/player_controller.dart';
import '../../providers/dynamic_color_provider.dart';
import '../../utils/color_extractor.dart';
import '../../utils/app_colors.dart';

@RoutePage()
class DurationUpdateScreen extends ConsumerWidget {
  const DurationUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationState = ref.watch(durationControllerProvider);
    final durationController = ref.read(durationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tools'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Duration Update Section
            _buildDurationUpdateSection(durationState, durationController),
            
            const SizedBox(height: 32),
            
            // Color Testing Section
            _buildColorTestingSection(context, ref),
            
            const SizedBox(height: 32),
            
            // Elegant Palettes Preview
            _buildElegantPalettesSection(context, ref),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDurationUpdateSection(DurationState durationState, DurationController durationController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto Update Song Durations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will automatically detect and update song durations from MP3 files for all songs with duration = 0.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        if (durationState.isUpdating) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  LinearProgressIndicator(
                    value: durationState.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress text
                  Text(
                    '${durationState.processedSongs} / ${durationState.totalSongs} songs processed',
                    style: const TextStyle(fontSize: 14),
                  ),
                  
                  if (durationState.currentSongTitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Processing: ${durationState.currentSongTitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (durationState.isCompleted) ...[
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Update Completed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('✅ Success: ${durationState.successCount} songs'),
                  Text('❌ Failed: ${durationState.failCount} songs'),
                  Text('📊 Total: ${durationState.totalSongs} songs'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (durationState.error != null) ...[
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    durationState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: durationState.isUpdating 
                    ? null 
                    : () => durationController.updateAllSongsDuration(),
                icon: durationState.isUpdating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  durationState.isUpdating 
                      ? 'Updating...' 
                      : 'Start Update',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: durationState.isUpdating 
                    ? null 
                    : () => durationController.reset(),
                icon: const Icon(Icons.clear),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildColorTestingSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎨 Color Extraction Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test the new smart color extraction algorithm',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Test with current song
            Consumer(
              builder: (context, ref, child) {
                final playerState = ref.watch(playerControllerProvider);
                final currentSong = playerState.currentSong;
                
                if (currentSong == null) {
                  return const Text(
                    'No song currently playing',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Song:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            currentSong.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'by ${currentSong.artist}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Test color extraction with verbose output
                        await ColorExtractor.testColorExtraction(
                          currentSong.albumArtUrl,
                          verbose: true,
                        );
                        
                        // Force refresh dynamic colors
                        ref.read(dynamicColorProvider.notifier)
                          .clearColorsForSong(currentSong.id);
                        ref.read(dynamicColorProvider.notifier)
                          .extractColorsFromSong(currentSong);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Color extraction test completed! Check console for details.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.palette),
                      label: const Text('Test Color Extraction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Force complete refresh with cache clear
                        ref.read(dynamicColorProvider.notifier).forceRefresh();
                        
                        // Wait a moment then re-extract
                        await Future.delayed(const Duration(milliseconds: 200));
                        ref.read(dynamicColorProvider.notifier)
                          .extractColorsFromSong(currentSong);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎨 Colors refreshed with new algorithm!'),
                            backgroundColor: Colors.purple,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Force Refresh Colors'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildElegantPalettesSection(BuildContext context, WidgetRef ref) {
    final paletteKeys = ColorExtractor.getElegantPaletteKeys();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎭 Elegant Color Palettes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preview and test the available elegant color palettes',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            ...paletteKeys.map((key) {
              final palette = ColorExtractor.getElegantPalette(key);
              if (palette == null) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Color preview
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Palette info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            key.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Primary: ${palette.primary.toString()}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Accent: ${palette.accent.toString()}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Test button
                    ElevatedButton(
                      onPressed: () {
                        // Apply this palette temporarily
                        ref.read(dynamicColorProvider.notifier).state = 
                          ref.read(dynamicColorProvider).copyWith(
                            colors: palette,
                          );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Applied $key palette'),
                            backgroundColor: palette.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 

