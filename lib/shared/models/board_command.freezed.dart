// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_command.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoardCommand {

 String get id; String get command; String get label; String get description;
/// Create a copy of BoardCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardCommandCopyWith<BoardCommand> get copyWith => _$BoardCommandCopyWithImpl<BoardCommand>(this as BoardCommand, _$identity);

  /// Serializes this BoardCommand to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardCommand&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,command,label,description);

@override
String toString() {
  return 'BoardCommand(id: $id, command: $command, label: $label, description: $description)';
}


}

/// @nodoc
abstract mixin class $BoardCommandCopyWith<$Res>  {
  factory $BoardCommandCopyWith(BoardCommand value, $Res Function(BoardCommand) _then) = _$BoardCommandCopyWithImpl;
@useResult
$Res call({
 String id, String command, String label, String description
});




}
/// @nodoc
class _$BoardCommandCopyWithImpl<$Res>
    implements $BoardCommandCopyWith<$Res> {
  _$BoardCommandCopyWithImpl(this._self, this._then);

  final BoardCommand _self;
  final $Res Function(BoardCommand) _then;

/// Create a copy of BoardCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? command = null,Object? label = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardCommand].
extension BoardCommandPatterns on BoardCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardCommand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardCommand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardCommand value)  $default,){
final _that = this;
switch (_that) {
case _BoardCommand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardCommand value)?  $default,){
final _that = this;
switch (_that) {
case _BoardCommand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String command,  String label,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardCommand() when $default != null:
return $default(_that.id,_that.command,_that.label,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String command,  String label,  String description)  $default,) {final _that = this;
switch (_that) {
case _BoardCommand():
return $default(_that.id,_that.command,_that.label,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String command,  String label,  String description)?  $default,) {final _that = this;
switch (_that) {
case _BoardCommand() when $default != null:
return $default(_that.id,_that.command,_that.label,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardCommand implements BoardCommand {
  const _BoardCommand({required this.id, required this.command, required this.label, this.description = ''});
  factory _BoardCommand.fromJson(Map<String, dynamic> json) => _$BoardCommandFromJson(json);

@override final  String id;
@override final  String command;
@override final  String label;
@override@JsonKey() final  String description;

/// Create a copy of BoardCommand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardCommandCopyWith<_BoardCommand> get copyWith => __$BoardCommandCopyWithImpl<_BoardCommand>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardCommandToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardCommand&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,command,label,description);

@override
String toString() {
  return 'BoardCommand(id: $id, command: $command, label: $label, description: $description)';
}


}

/// @nodoc
abstract mixin class _$BoardCommandCopyWith<$Res> implements $BoardCommandCopyWith<$Res> {
  factory _$BoardCommandCopyWith(_BoardCommand value, $Res Function(_BoardCommand) _then) = __$BoardCommandCopyWithImpl;
@override @useResult
$Res call({
 String id, String command, String label, String description
});




}
/// @nodoc
class __$BoardCommandCopyWithImpl<$Res>
    implements _$BoardCommandCopyWith<$Res> {
  __$BoardCommandCopyWithImpl(this._self, this._then);

  final _BoardCommand _self;
  final $Res Function(_BoardCommand) _then;

/// Create a copy of BoardCommand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? command = null,Object? label = null,Object? description = null,}) {
  return _then(_BoardCommand(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
