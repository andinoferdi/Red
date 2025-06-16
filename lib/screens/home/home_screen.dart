import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:http/http.dart' as http;
import 'package:auto_route/auto_route.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/player_controller.dart';
import '../../utils/image_helpers.dart';
import '../../providers/play_history_provider.dart';
import '../../providers/genre_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/song_item_widget.dart';



import '../../utils/app_colors.dart';
import '../../utils/app_config.dart';
import '../debug/album_sync_debug_screen.dart';

// Helper function to check if host is reachable
Future<bool> isHostReachable(String url) async {
  try {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Timeout', 408);
      },
    );
    return response.statusCode < 400;
  } catch (e) {
    return false;
  }
}

// Test and determine the best PocketBase URL using AppConfig
Future<String> determinePocketBaseUrl() async {
  // Use the proper URL list from AppConfig (Android emulator prioritized)
  final List<String> possibleUrls = AppConfig.possibleUrls;
  
  
  for (final url in possibleUrls) {
    try {
      final response = await http.get(
        Uri.parse('$url/api/health'),
        headers: AppConfig.getHeadersForUrl(url),
      ).timeout(
        AppConfig.shortTimeout,
        onTimeout: () {
          return http.Response('Timeout', 408);
        },
      );
      
      if (response.statusCode < 400) {
        return url;
      }
    } catch (e) {
      // Continue to next URL
    }
  }
  
  // Use default URL from AppConfig if all fail
  return AppConfig.defaultUrl;
}

// PocketBase instance with lazy initialization
late PocketBase pb;
bool isPbInitialized = false;

// Provider to ensure PocketBase is initialized before use
final pocketBaseInitProvider = FutureProvider<PocketBase>((ref) async {
  if (!isPbInitialized) {
    final url = await determinePocketBaseUrl();
    pb = PocketBase(url);
    isPbInitialized = true;
  }
  return pb;
});

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Provider for recently played songs
final recentlyPlayedProvider = FutureProvider<List<RecordModel>>((ref) async {
  // First ensure PocketBase is initialized with correct URL
  await ref.watch(pocketBaseInitProvider.future);
  
  final authState = ref.watch(authControllerProvider);
  final userId = authState.user?.id;
  
  if (userId == null) {
    return [];
  }
  
  try {
    // Verify we can reach the server
    final isReachable = await isHostReachable('${pb.baseUrl}/api/collections/user_history/records');
    if (!isReachable) {
      return [];
    }
    
    // First try direct filter on user_id
    var recentlyPlayed = await pb.collection('user_history').getList(
      page: 1,
      perPage: 3,
      filter: 'user_id = "$userId"',
      sort: '-played_at',
      expand: 'song_id',
    );
    
    return recentlyPlayed.items;
  } catch (e) {
    return [];
  }
});

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs
  
  bool _hasLoadedInitialData = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load data on init using new providers
    Future.microtask(() {
      if (!_hasLoadedInitialData) {
        ref.read(playHistoryProvider.notifier).loadRecentlyPlayed();
        ref.read(genreProvider.notifier).loadGenres();
        _hasLoadedInitialData = true;
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh data when app comes back to foreground (user returns from other apps)
    if (state == AppLifecycleState.resumed && _hasLoadedInitialData && mounted) {
      Future.microtask(() {
        ref.read(playHistoryProvider.notifier).loadRecentlyPlayed();
      });
    }
  }
  
  Future<void> _refreshData() async {
    // Manual refresh via pull-to-refresh using new providers
    await Future.wait([
      ref.read(playHistoryProvider.notifier).loadRecentlyPlayed(),
      ref.read(genreProvider.notifier).loadGenres(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Removed auto-refresh listener to prevent Recently Played list from reordering
    // while user is interacting with the home screen. Data will only refresh when:
    // 1. User first opens the app
    // 2. User navigates back to home screen from other screens
    // 3. User manually pulls to refresh (if implemented)
    
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      // Use resizeToAvoidBottomInset: false to prevent keyboard from pushing up content
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // We'll handle bottom padding ourselves
        bottom: false,
                  child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        _buildContinueListening(context),
                        const SizedBox(height: 30),
                        _buildYourTopMixes(context),
                        const SizedBox(height: 30),
                        _buildRecentListening(context),
                        // Add a bottom spacing to account for the navigation bar and mini player
                        SizedBox(height: 70 + bottomPadding + 64), // Added 64 for mini player
                      ],
                    ),
                  ),
                ),
              ),
            // Mini Player
            const MiniPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    // Get the PocketBase URL
    final pocketBaseUrl = ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with explore and library screens
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
                  width: 145, // Match width constraint with other screens
                  child: const Text(
                    'Home',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      color: Colors.white,
                      fontSize: 25, // Match size with other screens
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.router.push(const StatsRoute());
                  },
                  child: const Icon(Icons.stacked_line_chart,
                      color: Colors.white, size: 28), // Match icon size
                ),
                const SizedBox(width: 16),
                Stack(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 28), // Match icon size
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    _showProfileMenu(context);
                  },
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 28), // Match icon size
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueListening(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Continue Listening',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            // Watch new genre provider
            final genreState = ref.watch(genreProvider);
            
            // Show loading state
            if (genreState.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Show error state
            if (genreState.error != null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Error: ${genreState.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            
            // Show empty state
            if (genreState.genres.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No genres available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            
            // Get the PocketBase URL for image URLs
            
            // Show genres grid
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: genreState.genres.take(6).map((genre) {
                  // Map genre icon names to Material icons
                  IconData icon = Icons.music_note;
                  final genreName = genre.name.toLowerCase();
                  
                  if (genreName.contains('jazz')) {
                    icon = Icons.coffee;
                  } else if (genreName.contains('release')) {
                    icon = Icons.new_releases;
                  } else if (genreName.contains('anything')) {
                    icon = Icons.all_inclusive;
                  } else if (genreName.contains('anime')) {
                    icon = Icons.music_note;
                  } else if (genreName.contains('house')) {
                    icon = Icons.house;
                  } else if (genreName.contains('lo-fi')) {
                    icon = Icons.headphones;
                  }
                  
                  return _buildPlaylistCard(
                    genre.name,
                    icon,
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: AppColors.homeGradient,
                    ),
                    imageUrl: genre.iconUrl,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Updating the _buildPlaylistCard method to accept an image URL
  Widget _buildPlaylistCard(
    String title,
    IconData icon, {
    LinearGradient? gradient,
    Color iconColor = Colors.white,
    String? imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (imageUrl != null && ImageHelpers.isValidImageUrl(imageUrl))
              ImageHelpers.buildSafeNetworkImage(
                imageUrl: imageUrl,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(4),
                fallbackWidget: Icon(icon, color: iconColor),
              )
            else
              Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final userName = user?.getName() ?? 'User';
    final userEmail = user?.getEmail() ?? '';
    
    // Get the PocketBase URL
    final pocketBaseUrl = ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
                          backgroundColor: AppColors.surface,
          title: const Text(
            'Profile Options',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User profile info section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    // Avatar
                    UserAvatar(
                      user: user,
                      baseUrl: pocketBaseUrl,
                      size: 60,
                      iconSize: 36,
                    ),
                    const SizedBox(width: 16),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.white),
                title: const Text(
                  'View Profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Add profile view navigation here
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text(
                  'Album Sync Tool',
                  style: TextStyle(color: Colors.orange),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    AppRouter.createConsistentRoute(
                      const AlbumSyncDebugScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Logout logic
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.router.replace(const AuthOptionsRoute());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Remaining method implementations would follow...
  Widget _buildYourTopMixes(BuildContext context) {
    // Implementation would be here
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Your Top Mixes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            children: [
              _buildMixCard(
                'Pop Mix',
                Colors.red.shade400,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              const SizedBox(width: 16),
              _buildMixCard(
                'Chill Mix',
                Colors.amber.shade400,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  context.router.push(const LibraryRoute());
                },
                child: _buildMixCard(
                  'Lofi Mix',
                  Colors.blue.shade400,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentListening(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recently Played',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            // Watch new play history provider
            final playHistoryState = ref.watch(playHistoryProvider);
            
            // Show loading indicator
            if (playHistoryState.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Show error
            if (playHistoryState.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Text(
                    'Error: ${playHistoryState.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            
            // Show empty state
            if (playHistoryState.recentlyPlayed.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No recently played songs',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            
            // Show list of recently played songs
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playHistoryState.recentlyPlayed.length,
              itemBuilder: (context, index) {
                final song = playHistoryState.recentlyPlayed[index];
                
                return Column(
                  children: [
                    SongItemWidget(
                      song: song,
                      subtitle: 'Song • ${song.artist}',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                      onTap: () {
                        // Use playSongById to load complete song data without playlist context
                        ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
                        
                        // Color extraction will be handled automatically by mini_player when song changes
                      },
                    ),
                    if (index < playHistoryState.recentlyPlayed.length - 1)
                      const SizedBox(height: 4),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMixCard(
    String title,
    Color color, {
    required Gradient gradient,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Based on your listening',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


