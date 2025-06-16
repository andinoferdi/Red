// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthStateImpl _$$AuthStateImplFromJson(Map<String, dynamic> json) =>
    _$AuthStateImpl(
      user: json['user'] == null
          ? null
          : RecordModel.fromJson(json['user'] as Map<String, dynamic>),
      isLoading: json['isLoading'] as bool? ?? false,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      error: json['error'] as String?,
      successMessage: json['successMessage'] as String?,
    );

Map<String, dynamic> _$$AuthStateImplToJson(_$AuthStateImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
      'isLoading': instance.isLoading,
      'isAuthenticated': instance.isAuthenticated,
      'error': instance.error,
      'successMessage': instance.successMessage,
    };
