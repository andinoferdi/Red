import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

/// Authentication state
@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    RecordModel? user,
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    String? error,
    String? successMessage,
  }) = _AuthState;

  factory AuthState.fromJson(Map<String, dynamic> json) => 
      _$AuthStateFromJson(json);

  /// Initial auth state
  factory AuthState.initial() => const AuthState();

  /// Loading auth state
  factory AuthState.loading() => const AuthState(isLoading: true);

  /// Authenticated auth state
  factory AuthState.authenticated(RecordModel user) => AuthState(
        user: user,
        isAuthenticated: true,
      );

  /// Unauthenticated auth state
  factory AuthState.unauthenticated() => const AuthState(isAuthenticated: false);

  /// Error auth state
  factory AuthState.error(String message) => AuthState(
        error: message,
        isLoading: false,
      );
        
  /// Registration success state
  factory AuthState.registrationSuccess(String message) => AuthState(
        successMessage: message,
        isLoading: false,
      );
}
