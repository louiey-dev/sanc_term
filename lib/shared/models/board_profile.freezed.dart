// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoardProfile {

 String get id; String get name; String get port; int get baudRate; TargetType get targetType; String? get ipAddress; bool get isDefault; DateTime? get lastUsed;
/// Create a copy of BoardProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardProfileCopyWith<BoardProfile> get copyWith => _$BoardProfileCopyWithImpl<BoardProfile>(this as BoardProfile, _$identity);

  /// Serializes this BoardProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.port, port) || other.port == port)&&(identical(other.baudRate, baudRate) || other.baudRate == baudRate)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.lastUsed, lastUsed) || other.lastUsed == lastUsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,port,baudRate,targetType,ipAddress,isDefault,lastUsed);

@override
String toString() {
  return 'BoardProfile(id: $id, name: $name, port: $port, baudRate: $baudRate, targetType: $targetType, ipAddress: $ipAddress, isDefault: $isDefault, lastUsed: $lastUsed)';
}


}

/// @nodoc
abstract mixin class $BoardProfileCopyWith<$Res>  {
  factory $BoardProfileCopyWith(BoardProfile value, $Res Function(BoardProfile) _then) = _$BoardProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String port, int baudRate, TargetType targetType, String? ipAddress, bool isDefault, DateTime? lastUsed
});




}
/// @nodoc
class _$BoardProfileCopyWithImpl<$Res>
    implements $BoardProfileCopyWith<$Res> {
  _$BoardProfileCopyWithImpl(this._self, this._then);

  final BoardProfile _self;
  final $Res Function(BoardProfile) _then;

/// Create a copy of BoardProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? port = null,Object? baudRate = null,Object? targetType = null,Object? ipAddress = freezed,Object? isDefault = null,Object? lastUsed = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as String,baudRate: null == baudRate ? _self.baudRate : baudRate // ignore: cast_nullable_to_non_nullable
as int,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as TargetType,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,lastUsed: freezed == lastUsed ? _self.lastUsed : lastUsed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardProfile].
extension BoardProfilePatterns on BoardProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardProfile value)  $default,){
final _that = this;
switch (_that) {
case _BoardProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardProfile value)?  $default,){
final _that = this;
switch (_that) {
case _BoardProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String port,  int baudRate,  TargetType targetType,  String? ipAddress,  bool isDefault,  DateTime? lastUsed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardProfile() when $default != null:
return $default(_that.id,_that.name,_that.port,_that.baudRate,_that.targetType,_that.ipAddress,_that.isDefault,_that.lastUsed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String port,  int baudRate,  TargetType targetType,  String? ipAddress,  bool isDefault,  DateTime? lastUsed)  $default,) {final _that = this;
switch (_that) {
case _BoardProfile():
return $default(_that.id,_that.name,_that.port,_that.baudRate,_that.targetType,_that.ipAddress,_that.isDefault,_that.lastUsed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String port,  int baudRate,  TargetType targetType,  String? ipAddress,  bool isDefault,  DateTime? lastUsed)?  $default,) {final _that = this;
switch (_that) {
case _BoardProfile() when $default != null:
return $default(_that.id,_that.name,_that.port,_that.baudRate,_that.targetType,_that.ipAddress,_that.isDefault,_that.lastUsed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardProfile implements BoardProfile {
  const _BoardProfile({required this.id, required this.name, this.port = '', this.baudRate = 115200, this.targetType = TargetType.nvidia, this.ipAddress, this.isDefault = false, this.lastUsed});
  factory _BoardProfile.fromJson(Map<String, dynamic> json) => _$BoardProfileFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String port;
@override@JsonKey() final  int baudRate;
@override@JsonKey() final  TargetType targetType;
@override final  String? ipAddress;
@override@JsonKey() final  bool isDefault;
@override final  DateTime? lastUsed;

/// Create a copy of BoardProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardProfileCopyWith<_BoardProfile> get copyWith => __$BoardProfileCopyWithImpl<_BoardProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.port, port) || other.port == port)&&(identical(other.baudRate, baudRate) || other.baudRate == baudRate)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.lastUsed, lastUsed) || other.lastUsed == lastUsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,port,baudRate,targetType,ipAddress,isDefault,lastUsed);

@override
String toString() {
  return 'BoardProfile(id: $id, name: $name, port: $port, baudRate: $baudRate, targetType: $targetType, ipAddress: $ipAddress, isDefault: $isDefault, lastUsed: $lastUsed)';
}


}

/// @nodoc
abstract mixin class _$BoardProfileCopyWith<$Res> implements $BoardProfileCopyWith<$Res> {
  factory _$BoardProfileCopyWith(_BoardProfile value, $Res Function(_BoardProfile) _then) = __$BoardProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String port, int baudRate, TargetType targetType, String? ipAddress, bool isDefault, DateTime? lastUsed
});




}
/// @nodoc
class __$BoardProfileCopyWithImpl<$Res>
    implements _$BoardProfileCopyWith<$Res> {
  __$BoardProfileCopyWithImpl(this._self, this._then);

  final _BoardProfile _self;
  final $Res Function(_BoardProfile) _then;

/// Create a copy of BoardProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? port = null,Object? baudRate = null,Object? targetType = null,Object? ipAddress = freezed,Object? isDefault = null,Object? lastUsed = freezed,}) {
  return _then(_BoardProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as String,baudRate: null == baudRate ? _self.baudRate : baudRate // ignore: cast_nullable_to_non_nullable
as int,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as TargetType,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,lastUsed: freezed == lastUsed ? _self.lastUsed : lastUsed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
