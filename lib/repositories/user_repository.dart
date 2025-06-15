import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

/// Repository for handling user-related data
class UserRepository {
  final PocketBaseService _pocketBaseService;
  
  UserRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Login with email and password
  Future<RecordModel> login(String email, String password) async {
    try {
      final authData = await _pb.collection('users').authWithPassword(
        email,
        password,
      );
      
      if (authData.record == null) {
        throw Exception('Username or password is incorrect');
      }
      
      return authData.record!;
    } catch (e) {
      // Check if the error is related to authentication
      if (e.toString().contains('Failed to authenticate') || 
          e.toString().contains('400') ||
          e.toString().contains('auth-with') ||
          e.toString().contains('failed')) {
        throw Exception('Username or password is incorrect');
      }
      // For network errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') ||
          e.toString().contains('network')) {
        throw Exception('Network error. Please check your connection');
      }
      // For server errors
      if (e.toString().contains('500')) {
        throw Exception('Server error. Please try again later');
      }
      // Generic error fallback
      throw Exception('Login failed. Please try again');
    }
  }
  
  /// Register a new user
  Future<RecordModel> register(String email, String password, String name) async {
    try {
      final userData = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
      };
      
      return await _pb.collection('users').create(body: userData);
    } catch (e) {
      // Check if it's an email already exists error
      if (e.toString().contains('email') && e.toString().contains('exists')) {
        throw Exception('An account with this email already exists');
      }
      
      // Extract specific validation errors from PocketBase response
      if (e.toString().contains('validation_min_text_constraint') && 
          e.toString().contains('password')) {
        throw Exception('Password must be at least 6 characters');
      }
      
      if (e.toString().contains('validation') && e.toString().contains('password')) {
        throw Exception('Password validation failed. Please use a stronger password');
      }
      
      if (e.toString().contains('validation') && e.toString().contains('email')) {
        throw Exception('Please enter a valid email address');
      }
      
      if (e.toString().contains('data')) {
        // Try to extract more specific error message
        final errorMsg = e.toString();
        if (errorMsg.contains('message:')) {
          final messagePart = errorMsg.split('message:').last.split(',').first;
          if (messagePart.length > 5 && messagePart.length < 100) {
            throw Exception('Registration error: ${messagePart.trim()}');
          }
        }
      }
      
      // Generic fallback
      throw Exception('Registration failed. Please check your information and try again');
    }
  }
  
  /// Logout the current user
  Future<void> logout() async {
    try {
      // Clear the auth store
      _pb.authStore.clear();
    } catch (e) {
      // Always clear auth even if server logout fails
      _pb.authStore.clear();
      throw Exception('Logout failed: $e');
    }
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;
  
  /// Get current user info
  RecordModel? get currentUser => _pb.authStore.model;
  
  /// Get user profile
  Future<RecordModel> getUserProfile(String userId) async {
    try {
      return await _pb.collection('users').getOne(userId);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  /// Update user profile
  Future<RecordModel> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      return await _pb.collection('users').update(userId, body: data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
  
  /// Refresh authentication
  Future<void> refreshAuth() async {
    try {
      if (_pb.authStore.isValid) {
        await _pb.collection('users').authRefresh();
      }
    } catch (e) {
      // If refresh fails, clear auth
      _pb.authStore.clear();
      throw Exception('Failed to refresh authentication: $e');
    }
  }
  
  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      await _pb.collection('users').requestPasswordReset(email);
    } catch (e) {
      // Check if it's a network error
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') ||
          e.toString().contains('network')) {
        throw Exception('Network error. Please check your connection');
      }
      
      // Check if it's a "not found" error (email doesn't exist)
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        // We don't want to reveal if an email exists or not for security reasons
        // So instead of an error, we'll return success to prevent user enumeration attacks
        return;
      }
      
      // Generic error
      throw Exception('Failed to send password reset email. Please try again later.');
    }
  }
  
  /// Check if an email exists in the database
  Future<RecordModel?> checkEmailExists(String email) async {
    try {
      // Pastikan email dalam format lowercase untuk menghindari masalah case sensitivity
      final emailLowercase = email.toLowerCase().trim();
      
      
      // Coba dengan filter yang lebih sederhana
      final result = await _pb.collection('users').getList(
        filter: 'email ~ "$emailLowercase"',  // Menggunakan operator ~ untuk pencarian yang lebih fleksibel
        page: 1,
        perPage: 10,  // Meningkatkan jumlah hasil untuk debugging
      );
      
      if (result.items.isEmpty) {
        return null;
      }
      
      // Cari email yang tepat sama
      for (final item in result.items) {
        if (item.data['email'].toString().toLowerCase() == emailLowercase) {
          return item;
        }
      }
      
      // Jika tidak ada yang cocok persis
      return null;
    } catch (e) {
      // Untuk debugging, lemparkan error agar dapat dilihat
      throw Exception("Error mencari email: $e");
    }
  }
  
  /// Update user password directly
  Future<RecordModel> updatePassword(String userId, String newPassword) async {
    try {
      // Update the user's password
      return await _pb.collection('users').update(
        userId,
        body: {
          'password': newPassword,
          'passwordConfirm': newPassword,
        },
      );
    } catch (e) {
      // Check if it's a validation error
      if (e.toString().contains('validation')) {
        if (e.toString().contains('min')) {
          throw Exception('Password must be at least 6 characters');
        }
        throw Exception('Password validation failed. Please use a stronger password');
      }
      
      // Generic error
      throw Exception('Failed to update password. Please try again later');
    }
  }
  
  /// Reset password directly with email (tanpa memerlukan user ID)
  Future<Map<String, dynamic>> resetPasswordDirect(String email, String newPassword) async {
    try {
      
      // Pendekatan 1: Menggunakan filter yang lebih tepat untuk menemukan user
      try {
        
        // Cari user dengan filter yang lebih tepat
        final searchResult = await _pb.collection('users').getList(
          filter: 'email = "$email"', // Gunakan exact match dengan =
          sort: '-created',
        );
        
        if (searchResult.items.isNotEmpty) {
          final userId = searchResult.items[0].id;
          
          // Update password user
          await _pb.collection('users').update(
            userId,
            body: {
              'password': newPassword,
              'passwordConfirm': newPassword,
            },
          );
          
          return {'success': true, 'method': 'exact_match_update'};
        }
              } catch (e) {
      }
      
      // Pendekatan 2: Menggunakan API sendiri untuk pengubahan password langsung
      try {
        
        // Mencari user dengan email di database (case insensitive)
        final emailLower = email.toLowerCase();
        final users = await _pb.collection('users').getList(
          filter: 'LOWER(email) ~ "$emailLower"',
          sort: '-created',
        );
        
        // Temukan yang cocok persis
        for (final user in users.items) {
          final userEmail = user.data['email'].toString().toLowerCase();
          if (userEmail == emailLower) {
            
            // Update password
            await _pb.collection('users').update(
              user.id,
              body: {
                'password': newPassword,
                'passwordConfirm': newPassword,
              },
            );
            
            return {'success': true, 'method': 'admin_reset'};
          }
        }
              } catch (e) {
      }
      
      // Pendekatan 3: Menggunakan collection API langsung
      try {
        
        // Gunakan getFullList dengan filter yang lebih spesifik
        final records = await _pb.collection('users').getFullList(
          filter: 'email = "$email"',
        );
        
        if (records.isNotEmpty) {
          final userId = records[0].id;
          
          // Reset password
          await _pb.collection('users').update(
            userId,
            body: {
              'password': newPassword,
              'passwordConfirm': newPassword,
            },
          );
          
          return {'success': true, 'method': 'direct_collection_api'};
        }
              } catch (e) {
      }
      
      // Jika sampai di sini, berarti tidak berhasil mengubah password
      return {
        'success': false,
        'error': 'Tidak dapat menemukan akun dengan email $email. Silakan periksa alamat email Anda.'
      };
    } catch (e) {
      
      return {
        'success': false,
        'error': 'Gagal reset password: $e'
      };
    }
  }
}


