import 'package:flutter/material.dart';

class SpotifyStyleButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const SpotifyStyleButton({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // Slightly larger radius
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 8), // Compact padding seperti sebelumnya
        child: Row(
          children: [
            // Plus icon in circle - Spotify style (bigger)
            Container(
              width: 52, // Slightly smaller for Spotify-like compact look
              height: 52, // Slightly smaller for Spotify-like compact look
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28, // Increased from 24
              ),
            ),
            const SizedBox(width: 16), // Compact spacing like Spotify
            // Text
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18, // Increased from 16
                  fontWeight: FontWeight.w500, // Using Gotham medium weight
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 

