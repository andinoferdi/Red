import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../routes/app_router.dart';
import '../utils/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final double bottomPadding;
  
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    this.bottomPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 + bottomPadding,
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.divider,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () {
                // Navigate to home
                if (currentIndex != 0) {
                  context.router.replace(const HomeRoute());
                }
              },
            ),
            _buildNavItem(
              icon: Icons.search,
              label: 'Explore',
              isSelected: currentIndex == 1,
              onTap: () {
                // Navigate to explore
                if (currentIndex != 1) {
                  context.router.replace(const ExploreRoute());
                }
              },
            ),
            _buildNavItem(
              icon: Icons.library_music,
              label: 'Library',
              isSelected: currentIndex == 2,
              onTap: () {
                // Navigate to library
                if (currentIndex != 2) {
                  context.router.replace(const LibraryRoute());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navIndicator : AppColors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.navSelected : AppColors.grey,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.navSelected : AppColors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
