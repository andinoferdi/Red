import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../utils/image_helpers.dart';
import '../utils/app_colors.dart';

/// A reusable widget to display the user's avatar
class UserAvatar extends ConsumerWidget {
  /// The user record from PocketBase
  final RecordModel? user;
  
  /// The PocketBase server URL
  final String? baseUrl;
  
  /// The size of the avatar (both width and height)
  final double size;
  
  /// The size of the icon shown when no avatar is available
  final double iconSize;
  
  /// Border color for the avatar container
  final Color borderColor;
  
  /// Background color for the avatar container
  final Color backgroundColor;
  
  /// Create a new UserAvatar widget
  const UserAvatar({
    super.key,
    required this.user,
    required this.baseUrl,
    this.size = 50,
    this.iconSize = 30,
    this.borderColor = AppColors.greyDark,
    this.backgroundColor = AppColors.greyDark,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get avatar URL if available
    final avatarUrl = user?.getAvatarUrl(baseUrl);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
        color: backgroundColor,
      ),
      child: avatarUrl != null 
        ? ImageHelpers.buildSafeNetworkImage(
            imageUrl: avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(size / 2), // Make it circular
            showLoadingIndicator: true,
            fallbackWidget: Icon(
              Icons.person,
              color: AppColors.text,
              size: iconSize,
            ),
          )
        : Icon(
            Icons.person,
            color: AppColors.text,
            size: iconSize,
          ),
    );
  }
}
