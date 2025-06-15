import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/album_image_sync_tool.dart';
import '../../utils/app_colors.dart';

class AlbumSyncDebugScreen extends ConsumerStatefulWidget {
  const AlbumSyncDebugScreen({super.key});

  @override
  ConsumerState<AlbumSyncDebugScreen> createState() => _AlbumSyncDebugScreenState();
}

class _AlbumSyncDebugScreenState extends ConsumerState<AlbumSyncDebugScreen> {
  final _albumIdController = TextEditingController();
  final _newFileNameController = TextEditingController();
  bool _isLoading = false;
  String _output = '';

  @override
  void dispose() {
    _albumIdController.dispose();
    _newFileNameController.dispose();
    super.dispose();
  }

  void _addOutput(String message) {
    setState(() {
      _output += '$message\n';
    });
  }

  Future<void> _checkAllAlbums() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      final pbService = PocketBaseService();
      final tool = AlbumImageSyncTool(pbService);
      
      _addOutput('🔍 Starting album image check...\n');
      
      // Override debugPrint to capture output
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addOutput(message);
        }
        originalDebugPrint(message, wrapWidth: wrapWidth);
      };
      
      await tool.checkAllAlbumImages();
      
      // Restore original debugPrint
      debugPrint = originalDebugPrint;
      
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _listAlbumFiles() async {
    if (_albumIdController.text.trim().isEmpty) {
      _addOutput('⚠️ Please enter Album ID');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pbService = PocketBaseService();
      final tool = AlbumImageSyncTool(pbService);
      
      _addOutput('\n🔍 Listing files for album: ${_albumIdController.text.trim()}\n');
      
      // Override debugPrint to capture output
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addOutput(message);
        }
        originalDebugPrint(message, wrapWidth: wrapWidth);
      };
      
      await tool.listAlbumFiles(_albumIdController.text.trim());
      
      // Restore original debugPrint
      debugPrint = originalDebugPrint;
      
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAlbumCover() async {
    if (_albumIdController.text.trim().isEmpty || _newFileNameController.text.trim().isEmpty) {
      _addOutput('⚠️ Please enter both Album ID and new file name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pbService = PocketBaseService();
      final tool = AlbumImageSyncTool(pbService);
      
      _addOutput('\n🔄 Updating album cover...\n');
      
      // Override debugPrint to capture output
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addOutput(message);
        }
        originalDebugPrint(message, wrapWidth: wrapWidth);
      };
      
      await tool.updateAlbumCoverImage(
        _albumIdController.text.trim(),
        _newFileNameController.text.trim(),
      );
      
      // Restore original debugPrint
      debugPrint = originalDebugPrint;
      
      _addOutput('\n✅ Update completed! You may need to restart the app to see changes.\n');
      
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        title: const Text('Album Image Sync Tool'),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tool ini membantu memperbaiki masalah album cover yang tidak muncul setelah upload ulang gambar di PocketBase.\n\n'
                '1. Klik "Check All Albums" untuk melihat status semua album\n'
                '2. Masukkan Album ID dan klik "List Files" untuk melihat file yang ada\n'
                '3. Masukkan nama file yang benar dan klik "Update Cover" untuk memperbaiki',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            
            // Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkAllAlbums,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check All Albums'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _output = '';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greyDark,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Output'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Album ID input
            TextField(
              controller: _albumIdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Album ID',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // New file name input
            TextField(
              controller: _newFileNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Cover Image File Name (e.g., cover_new_abc123.jpg)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _listAlbumFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('List Files'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAlbumCover,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Cover'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Output
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? 'Output will appear here...' : _output,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 