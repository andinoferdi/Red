import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class GenreCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final bool isGradient;
  final VoidCallback? onTap;

  const GenreCard({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    this.isGradient = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            if (isGradient)
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.green.shade300,
                        Colors.green.shade500,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      radius: 0.8,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    icon,
                    color: AppColors.textOnPrimary,
                    size: 32,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 