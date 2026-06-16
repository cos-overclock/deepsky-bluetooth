// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'uuid.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeepskyUuid {

 String get value;
/// Create a copy of DeepskyUuid
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<DeepskyUuid> get copyWith => _$DeepskyUuidCopyWithImpl<DeepskyUuid>(this as DeepskyUuid, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyUuid&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class $DeepskyUuidCopyWith<$Res>  {
  factory $DeepskyUuidCopyWith(DeepskyUuid value, $Res Function(DeepskyUuid) _then) = _$DeepskyUuidCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$DeepskyUuidCopyWithImpl<$Res>
    implements $DeepskyUuidCopyWith<$Res> {
  _$DeepskyUuidCopyWithImpl(this._self, this._then);

  final DeepskyUuid _self;
  final $Res Function(DeepskyUuid) _then;

/// Create a copy of DeepskyUuid
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeepskyUuid].
extension DeepskyUuidPatterns on DeepskyUuid {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyUuid value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyUuid() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyUuid value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyUuid():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyUuid value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyUuid() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyUuid() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _DeepskyUuid():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyUuid() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyUuid extends DeepskyUuid {
  const _DeepskyUuid(this.value): super._();
  

@override final  String value;

/// Create a copy of DeepskyUuid
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyUuidCopyWith<_DeepskyUuid> get copyWith => __$DeepskyUuidCopyWithImpl<_DeepskyUuid>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyUuid&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class _$DeepskyUuidCopyWith<$Res> implements $DeepskyUuidCopyWith<$Res> {
  factory _$DeepskyUuidCopyWith(_DeepskyUuid value, $Res Function(_DeepskyUuid) _then) = __$DeepskyUuidCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$DeepskyUuidCopyWithImpl<$Res>
    implements _$DeepskyUuidCopyWith<$Res> {
  __$DeepskyUuidCopyWithImpl(this._self, this._then);

  final _DeepskyUuid _self;
  final $Res Function(_DeepskyUuid) _then;

/// Create a copy of DeepskyUuid
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_DeepskyUuid(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DeepskyDeviceId {

 String get value;
/// Create a copy of DeepskyDeviceId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<DeepskyDeviceId> get copyWith => _$DeepskyDeviceIdCopyWithImpl<DeepskyDeviceId>(this as DeepskyDeviceId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyDeviceId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class $DeepskyDeviceIdCopyWith<$Res>  {
  factory $DeepskyDeviceIdCopyWith(DeepskyDeviceId value, $Res Function(DeepskyDeviceId) _then) = _$DeepskyDeviceIdCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$DeepskyDeviceIdCopyWithImpl<$Res>
    implements $DeepskyDeviceIdCopyWith<$Res> {
  _$DeepskyDeviceIdCopyWithImpl(this._self, this._then);

  final DeepskyDeviceId _self;
  final $Res Function(DeepskyDeviceId) _then;

/// Create a copy of DeepskyDeviceId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeepskyDeviceId].
extension DeepskyDeviceIdPatterns on DeepskyDeviceId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyDeviceId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyDeviceId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyDeviceId value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyDeviceId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyDeviceId value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyDeviceId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyDeviceId() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _DeepskyDeviceId():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyDeviceId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyDeviceId extends DeepskyDeviceId {
  const _DeepskyDeviceId(this.value): super._();
  

@override final  String value;

/// Create a copy of DeepskyDeviceId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyDeviceIdCopyWith<_DeepskyDeviceId> get copyWith => __$DeepskyDeviceIdCopyWithImpl<_DeepskyDeviceId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyDeviceId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class _$DeepskyDeviceIdCopyWith<$Res> implements $DeepskyDeviceIdCopyWith<$Res> {
  factory _$DeepskyDeviceIdCopyWith(_DeepskyDeviceId value, $Res Function(_DeepskyDeviceId) _then) = __$DeepskyDeviceIdCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$DeepskyDeviceIdCopyWithImpl<$Res>
    implements _$DeepskyDeviceIdCopyWith<$Res> {
  __$DeepskyDeviceIdCopyWithImpl(this._self, this._then);

  final _DeepskyDeviceId _self;
  final $Res Function(_DeepskyDeviceId) _then;

/// Create a copy of DeepskyDeviceId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_DeepskyDeviceId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
