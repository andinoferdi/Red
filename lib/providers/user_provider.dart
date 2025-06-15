import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../controllers/auth_controller.dart';
import '../services/pocketbase_service.dart';

/// State for user management
class UserState {
  final RecordModel? currentUser;
  final Map<String, RecordModel> userCache;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const UserState({
    this.currentUser,
    this.userCache = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  UserState copyWith({
    RecordModel? currentUser,
    Map<String, RecordModel>? userCache,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      userCache: userCache ?? this.userCache,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory UserState.initial() => const UserState();
}

/// Controller for managing users globally
class UserGlobalController extends StateNotifier<UserState> {
  final Ref _ref;
  final PocketBaseService _pbService;

  UserGlobalController(this._ref, this._pbService) : super(UserState.initial());

  /// Load current user info
  Future<void> loadCurrentUser() async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authState = _ref.read(authControllerProvider);
      
      if (!authState.isAuthenticated || authState.user == null) {
        state = state.copyWith(
          currentUser: null,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        return;
      }

      // Get fresh user data from server
      final userData = await _pbService.pb.collection('users').getOne(authState.user!.id);
      
      state = state.copyWith(
        currentUser: userData,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load current user: ${e.toString()}',
      );
    }
  }

  /// Load user by ID (with caching)
  Future<RecordModel?> loadUserById(String userId) async {
    // Check cache first
    if (state.userCache.containsKey(userId)) {
      return state.userCache[userId];
    }

    try {
      final userData = await _pbService.pb.collection('users').getOne(userId);
      
      // Update cache
      final updatedCache = Map<String, RecordModel>.from(state.userCache);
      updatedCache[userId] = userData;
      
      state = state.copyWith(
        userCache: updatedCache,
        lastUpdated: DateTime.now(),
      );
      
      return userData;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load user $userId: ${e.toString()}',
      );
      return null;
    }
  }

  /// Get user from cache
  RecordModel? getCachedUser(String userId) {
    return state.userCache[userId];
  }

  /// Get current user avatar URL
  String getCurrentUserAvatarUrl() {
    if (state.currentUser == null) return '';
    
    try {
      return _pbService.pb.files.getUrl(
        state.currentUser!,
        state.currentUser!.data['avatar'] ?? '',
      ).toString();
    } catch (e) {
      return '';
    }
  }

  /// Get user avatar URL by user record
  String getUserAvatarUrl(RecordModel user) {
    try {
      return _pbService.pb.files.getUrl(
        user,
        user.data['avatar'] ?? '',
      ).toString();
    } catch (e) {
      return '';
    }
  }

  /// Get current user display name
  String getCurrentUserDisplayName() {
    if (state.currentUser == null) return 'Unknown User';
    
    final userData = state.currentUser!.data;
    return userData['name'] ?? userData['username'] ?? userData['email'] ?? 'Unknown User';
  }

  /// Get user display name by user record
  String getUserDisplayName(RecordModel user) {
    final userData = user.data;
    return userData['name'] ?? userData['username'] ?? userData['email'] ?? 'Unknown User';
  }

  /// Update current user profile
  Future<bool> updateCurrentUserProfile({
    String? name,
    String? avatar,
  }) async {
    if (state.currentUser == null) return false;

    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (avatar != null) updateData['avatar'] = avatar;

      if (updateData.isEmpty) return true;

      final updatedUser = await _pbService.pb.collection('users').update(
        state.currentUser!.id,
        body: updateData,
      );

      state = state.copyWith(
        currentUser: updatedUser,
        lastUpdated: DateTime.now(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update profile: ${e.toString()}',
      );
      return false;
    }
  }

  /// Refresh current user (force reload)
  Future<void> refreshCurrentUser() async {
    await loadCurrentUser();
  }

  /// Clear user cache
  void clearUserCache() {
    state = state.copyWith(
      userCache: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear specific user from cache
  void clearUserFromCache(String userId) {
    final updatedCache = Map<String, RecordModel>.from(state.userCache);
    updatedCache.remove(userId);
    
    state = state.copyWith(
      userCache: updatedCache,
      lastUpdated: DateTime.now(),
    );
  }

  /// Notify that user data has been updated
  void notifyUserUpdated() {
    state = state.copyWith(lastUpdated: DateTime.now());
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Handle user logout
  void handleLogout() {
    state = UserState.initial();
  }
}

/// Provider for PocketBaseService
final pocketBaseServiceProvider = Provider<PocketBaseService>((ref) {
  return PocketBaseService();
});

/// Provider for UserGlobalController
final userProvider = StateNotifierProvider<UserGlobalController, UserState>((ref) {
  final pbService = ref.watch(pocketBaseServiceProvider);
  return UserGlobalController(ref, pbService);
});

/// Auto-refresh provider for current user (refreshes every 10 minutes)
final autoRefreshUserProvider = StreamProvider<UserState>((ref) {
  return Stream.periodic(const Duration(minutes: 10), (count) {
    // Only refresh if user is authenticated and no error
    final authState = ref.read(authControllerProvider);
    final currentState = ref.read(userProvider);
    
    if (authState.isAuthenticated && currentState.error == null) {
      ref.read(userProvider.notifier).refreshCurrentUser();
    }
    return ref.read(userProvider);
  });
});

/// Provider for easy access to current user
final currentUserProvider = Provider<RecordModel?>((ref) {
  return ref.watch(userProvider).currentUser;
});

/// Provider for current user avatar URL
final currentUserAvatarProvider = Provider<String>((ref) {
  final userController = ref.watch(userProvider.notifier);
  return userController.getCurrentUserAvatarUrl();
});

/// Provider for current user display name
final currentUserDisplayNameProvider = Provider<String>((ref) {
  final userController = ref.watch(userProvider.notifier);
  return userController.getCurrentUserDisplayName();
});

/// Provider for getting user by ID (with caching)
final userByIdProvider = FutureProvider.family<RecordModel?, String>((ref, userId) async {
  final userController = ref.watch(userProvider.notifier);
  return await userController.loadUserById(userId);
}); 