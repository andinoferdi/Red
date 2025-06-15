import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/user_avatar.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import '../../widgets/playlist_tab.dart';
import '../../widgets/spotify_style_button.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/playlist_repository.dart';
import '../../widgets/mini_player.dart';
import '../../controllers/player_controller.dart';
import '../../routes/app_router.dart';
import '../../providers/playlist_provider.dart';

@RoutePage()
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {

  @override
  void initState() {
    super.initState();
    // Initialize playlist loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistProvider.notifier).loadPlaylists();
    });
  }

  void _showAdminOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Admin Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.orange),
                title: const Text(
                  'Update Song Durations',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Auto-detect durations from MP3 files',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.router.push(const DurationUpdateRoute());
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    // Watch auto-refresh playlist provider for automatic updates
    ref.watch(autoRefreshPlaylistProvider);
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // Pindahkan tombol ke atas, setelah header
                  _buildActionButtons(),
                  const SizedBox(
                      height:
                          16), // Spacing yang lebih kecil antara tombol dan content
                  Expanded(
                    child: PlaylistTab(),
                  ),
                  // Minimal spacing only
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Show mini player if there's a current song
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildHeader() {
    // Get the current authenticated user
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    // Get the PocketBase URL for constructing the avatar URL
    final pocketBaseUrl =
        ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with home and explore screens
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                UserAvatar(
                  user: user,
                  baseUrl: pocketBaseUrl,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 145, // Constrain width
                  child: GestureDetector(
                    onLongPress: () {
                      // Admin access through long press
                      _showAdminOptions(context);
                    },
                    child: const Text(
                      'Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25, // Match size with other screens
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DM Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.text,
                  size: 28, // Match size with other screens
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tambah Artist Button - Spotify Style
          SpotifyStyleButton(
            title: 'Tambahkan artis',
            onTap: () {
              // TODO: Implement add artist functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur Tambah Artist akan segera hadir!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          const SizedBox(height: 4), // Spacing yang ketat seperti sebelumnya
          // Tambah Playlist Button - Spotify Style
          SpotifyStyleButton(
            title: 'Tambahkan playlist',
            onTap: () {
              _showCreatePlaylistFlow();
            },
          ),
        ],
      ),
    );
  }



  void _showCreatePlaylistFlow() {
    _showCreatePlaylistDialog();
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor:
          Colors.black.withValues(alpha: 0.85), // Fixed deprecated withOpacity
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Check if mini player is active
            final playerState = ref.read(playerControllerProvider);
            final miniPlayerHeight = playerState.currentSong != null ? 64.0 : 0.0;
            
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: (MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 40) + miniPlayerHeight,
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.9, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.7, // Reduced height to accommodate mini player
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF212121),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4), // Fixed deprecated withOpacity
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          // Header with title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Text(
                              'Beri nama playlist-mu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'DM Sans',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Text Input with Spotify styling
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFF333333), // Slightly lighter than background
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.grey[800]!,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                ),
                                cursorColor:
                                    Colors.red, // Spotify green
                                decoration: InputDecoration(
                                  hintText: 'Playlist-ku',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                autofocus: true,
                              ),
                            ),
                          ),

                          // Buttons section - FIXED LAYOUT
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Cancel Button - Spotify style
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                        },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    minimumSize: const Size(100, 40),
                                  ),
                                  child: Text(
                                    'BATAL',
                                    style: TextStyle(
                                      color: isLoading
                                          ? Colors.grey[600]
                                          : Colors.grey[300],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'DM Sans',
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),

                                // Create Button - Spotify green style
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          final name = nameController.text.trim();
                                          final currentContext = context; // Store context before async
                                          
                                          if (name.isEmpty) {
                                            ScaffoldMessenger.of(currentContext)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Nama playlist tidak boleh kosong'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() {
                                            isLoading = true;
                                          });

                                          try {
                                            final pbService = PocketBaseService();
                                            final repository =
                                                PlaylistRepository(pbService);
                                            await repository.createPlaylist(
                                              name: name,
                                              description: '',
                                              isPublic: false,
                                              coverImageFile: null,
                                            );

                                            if (currentContext.mounted) {
                                              Navigator.of(currentContext).pop();
                                              
                                              // Auto-refresh using global provider
                                              ref.read(playlistProvider.notifier).notifyPlaylistUpdated();
                                              
                                              ScaffoldMessenger.of(currentContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.check_circle,
                                                          color: Colors.black),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Playlist "$name" berhasil dibuat!',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.white,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            setState(() {
                                              isLoading = false;
                                            });
                                            if (currentContext.mounted) {
                                              ScaffoldMessenger.of(currentContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.error_outline,
                                                          color: Colors.white),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                          child: Text(
                                                              'Gagal membuat playlist: ${e.toString()}')),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.red, // Spotify green
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                    minimumSize: const Size(100, 40),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'BUAT',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'DM Sans',
                                            letterSpacing: 1.2,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ));
          },
        );
      },
    );
  }
}


