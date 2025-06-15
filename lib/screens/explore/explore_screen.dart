import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_router.dart';
import '../../widgets/mini_player.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/genre_card.dart';

@RoutePage()
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false, // Don't apply bottom safe area to avoid double padding
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16), // Consistent top spacing
                    _buildSearchHeader(context, ref),
                    const SizedBox(height: 16), // Consistent spacing
                    _buildSearchBar(context),
                    const SizedBox(height: 24), // Adjusted spacing
                    _buildYourTopGenres(),
                    const SizedBox(height: 30),
                    _buildBrowseAll(),
                    // Add a bottom spacing to account for the navigation bar and mini player
                    SizedBox(height: 70 + bottomPadding + (playerState.currentSong != null ? 64 : 0)),
                  ],
                ),
              ),
            ),
          ),
          // Show mini player if there's a current song
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, WidgetRef ref) {
    // Get the current authenticated user
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    // Get the PocketBase URL for constructing the avatar URL
    final pocketBaseUrl = ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with home screen
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
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25, // Match size with other screens
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
                          Row(
              children: const [
                Icon(
                  Icons.search,
                  color: AppColors.text,
                  size: 28, // Match size with Library screen
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          // Navigate to search screen
          context.router.push(const SearchRoute());
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.greyDark, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: AppColors.greyLight,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Songs, Artists, Podcasts & More',
                style: TextStyle(
                  color: AppColors.greyLight,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYourTopGenres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Your Top Genres',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              GenreCard(
                title: 'Kpop',
                color: AppColors.genreKpop,
                icon: Icons.music_note,
              ),
              GenreCard(
                title: 'Indie',
                color: AppColors.genreIndie,
                icon: Icons.music_video,
              ),
              GenreCard(
                title: 'R&B',
                color: AppColors.genreRnB,
                icon: Icons.piano,
              ),
              GenreCard(
                title: 'Pop',
                color: AppColors.genrePop,
                icon: Icons.mic,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseAll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Browse All',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              GenreCard(
                title: 'Made\nfor You',
                color: AppColors.info,
                icon: Icons.person,
              ),
              GenreCard(
                title: 'RELEASED',
                color: AppColors.genreReleased,
                icon: Icons.new_releases,
                isGradient: true,
              ),
              GenreCard(
                title: 'Music\nCharts',
                color: AppColors.genreCharts,
                icon: Icons.equalizer,
              ),
              GenreCard(
                title: 'Podcasts',
                color: AppColors.genrePodcasts,
                icon: Icons.podcasts,
              ),
              GenreCard(
                title: 'Bollywood',
                color: AppColors.genreBollywood,
                icon: Icons.movie,
              ),
              GenreCard(
                title: 'Pop\nFusion',
                color: AppColors.genrePopFusion,
                icon: Icons.queue_music,
              ),
            ],
          ),
        ),
      ],
    );
  }


}
