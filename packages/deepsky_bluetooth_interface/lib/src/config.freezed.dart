// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeepskyBluetoothConfig {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyBluetoothConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeepskyBluetoothConfig()';
}


}

/// @nodoc
class $DeepskyBluetoothConfigCopyWith<$Res>  {
$DeepskyBluetoothConfigCopyWith(DeepskyBluetoothConfig _, $Res Function(DeepskyBluetoothConfig) __);
}


/// Adds pattern-matching-related methods to [DeepskyBluetoothConfig].
extension DeepskyBluetoothConfigPatterns on DeepskyBluetoothConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForegroundConfig value)?  foreground,TResult Function( BackgroundConfig value)?  background,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForegroundConfig() when foreground != null:
return foreground(_that);case BackgroundConfig() when background != null:
return background(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForegroundConfig value)  foreground,required TResult Function( BackgroundConfig value)  background,}){
final _that = this;
switch (_that) {
case ForegroundConfig():
return foreground(_that);case BackgroundConfig():
return background(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForegroundConfig value)?  foreground,TResult? Function( BackgroundConfig value)?  background,}){
final _that = this;
switch (_that) {
case ForegroundConfig() when foreground != null:
return foreground(_that);case BackgroundConfig() when background != null:
return background(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  foreground,TResult Function( IosBackgroundConfig? ios,  AndroidBackgroundConfig? android,  int? backgroundCallbackHandle)?  background,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForegroundConfig() when foreground != null:
return foreground();case BackgroundConfig() when background != null:
return background(_that.ios,_that.android,_that.backgroundCallbackHandle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  foreground,required TResult Function( IosBackgroundConfig? ios,  AndroidBackgroundConfig? android,  int? backgroundCallbackHandle)  background,}) {final _that = this;
switch (_that) {
case ForegroundConfig():
return foreground();case BackgroundConfig():
return background(_that.ios,_that.android,_that.backgroundCallbackHandle);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  foreground,TResult? Function( IosBackgroundConfig? ios,  AndroidBackgroundConfig? android,  int? backgroundCallbackHandle)?  background,}) {final _that = this;
switch (_that) {
case ForegroundConfig() when foreground != null:
return foreground();case BackgroundConfig() when background != null:
return background(_that.ios,_that.android,_that.backgroundCallbackHandle);case _:
  return null;

}
}

}

/// @nodoc


class ForegroundConfig implements DeepskyBluetoothConfig {
  const ForegroundConfig();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForegroundConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeepskyBluetoothConfig.foreground()';
}


}




/// @nodoc


class BackgroundConfig implements DeepskyBluetoothConfig {
  const BackgroundConfig({this.ios, this.android, this.backgroundCallbackHandle});


 final  IosBackgroundConfig? ios;
 final  AndroidBackgroundConfig? android;
 final  int? backgroundCallbackHandle;

/// Create a copy of DeepskyBluetoothConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundConfigCopyWith<BackgroundConfig> get copyWith => _$BackgroundConfigCopyWithImpl<BackgroundConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundConfig&&(identical(other.ios, ios) || other.ios == ios)&&(identical(other.android, android) || other.android == android)&&(identical(other.backgroundCallbackHandle, backgroundCallbackHandle) || other.backgroundCallbackHandle == backgroundCallbackHandle));
}


@override
int get hashCode => Object.hash(runtimeType,ios,android,backgroundCallbackHandle);

@override
String toString() {
  return 'DeepskyBluetoothConfig.background(ios: $ios, android: $android, backgroundCallbackHandle: $backgroundCallbackHandle)';
}


}

/// @nodoc
abstract mixin class $BackgroundConfigCopyWith<$Res> implements $DeepskyBluetoothConfigCopyWith<$Res> {
  factory $BackgroundConfigCopyWith(BackgroundConfig value, $Res Function(BackgroundConfig) _then) = _$BackgroundConfigCopyWithImpl;
@useResult
$Res call({
 IosBackgroundConfig? ios, AndroidBackgroundConfig? android, int? backgroundCallbackHandle
});


$IosBackgroundConfigCopyWith<$Res>? get ios;$AndroidBackgroundConfigCopyWith<$Res>? get android;

}
/// @nodoc
class _$BackgroundConfigCopyWithImpl<$Res>
    implements $BackgroundConfigCopyWith<$Res> {
  _$BackgroundConfigCopyWithImpl(this._self, this._then);

  final BackgroundConfig _self;
  final $Res Function(BackgroundConfig) _then;

/// Create a copy of DeepskyBluetoothConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ios = freezed,Object? android = freezed,Object? backgroundCallbackHandle = freezed,}) {
  return _then(BackgroundConfig(
ios: freezed == ios ? _self.ios : ios // ignore: cast_nullable_to_non_nullable
as IosBackgroundConfig?,android: freezed == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as AndroidBackgroundConfig?,backgroundCallbackHandle: freezed == backgroundCallbackHandle ? _self.backgroundCallbackHandle : backgroundCallbackHandle // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of DeepskyBluetoothConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IosBackgroundConfigCopyWith<$Res>? get ios {
    if (_self.ios == null) {
    return null;
  }

  return $IosBackgroundConfigCopyWith<$Res>(_self.ios!, (value) {
    return _then(_self.copyWith(ios: value));
  });
}/// Create a copy of DeepskyBluetoothConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AndroidBackgroundConfigCopyWith<$Res>? get android {
    if (_self.android == null) {
    return null;
  }

  return $AndroidBackgroundConfigCopyWith<$Res>(_self.android!, (value) {
    return _then(_self.copyWith(android: value));
  });
}
}

/// @nodoc
mixin _$IosBackgroundConfig {

 String get restoreIdentifier;
/// Create a copy of IosBackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IosBackgroundConfigCopyWith<IosBackgroundConfig> get copyWith => _$IosBackgroundConfigCopyWithImpl<IosBackgroundConfig>(this as IosBackgroundConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IosBackgroundConfig&&(identical(other.restoreIdentifier, restoreIdentifier) || other.restoreIdentifier == restoreIdentifier));
}


@override
int get hashCode => Object.hash(runtimeType,restoreIdentifier);

@override
String toString() {
  return 'IosBackgroundConfig(restoreIdentifier: $restoreIdentifier)';
}


}

/// @nodoc
abstract mixin class $IosBackgroundConfigCopyWith<$Res>  {
  factory $IosBackgroundConfigCopyWith(IosBackgroundConfig value, $Res Function(IosBackgroundConfig) _then) = _$IosBackgroundConfigCopyWithImpl;
@useResult
$Res call({
 String restoreIdentifier
});




}
/// @nodoc
class _$IosBackgroundConfigCopyWithImpl<$Res>
    implements $IosBackgroundConfigCopyWith<$Res> {
  _$IosBackgroundConfigCopyWithImpl(this._self, this._then);

  final IosBackgroundConfig _self;
  final $Res Function(IosBackgroundConfig) _then;

/// Create a copy of IosBackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restoreIdentifier = null,}) {
  return _then(_self.copyWith(
restoreIdentifier: null == restoreIdentifier ? _self.restoreIdentifier : restoreIdentifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IosBackgroundConfig].
extension IosBackgroundConfigPatterns on IosBackgroundConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IosBackgroundConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IosBackgroundConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IosBackgroundConfig value)  $default,){
final _that = this;
switch (_that) {
case _IosBackgroundConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IosBackgroundConfig value)?  $default,){
final _that = this;
switch (_that) {
case _IosBackgroundConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String restoreIdentifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IosBackgroundConfig() when $default != null:
return $default(_that.restoreIdentifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String restoreIdentifier)  $default,) {final _that = this;
switch (_that) {
case _IosBackgroundConfig():
return $default(_that.restoreIdentifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String restoreIdentifier)?  $default,) {final _that = this;
switch (_that) {
case _IosBackgroundConfig() when $default != null:
return $default(_that.restoreIdentifier);case _:
  return null;

}
}

}

/// @nodoc


class _IosBackgroundConfig implements IosBackgroundConfig {
  const _IosBackgroundConfig({required this.restoreIdentifier});


@override final  String restoreIdentifier;

/// Create a copy of IosBackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IosBackgroundConfigCopyWith<_IosBackgroundConfig> get copyWith => __$IosBackgroundConfigCopyWithImpl<_IosBackgroundConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IosBackgroundConfig&&(identical(other.restoreIdentifier, restoreIdentifier) || other.restoreIdentifier == restoreIdentifier));
}


@override
int get hashCode => Object.hash(runtimeType,restoreIdentifier);

@override
String toString() {
  return 'IosBackgroundConfig(restoreIdentifier: $restoreIdentifier)';
}


}

/// @nodoc
abstract mixin class _$IosBackgroundConfigCopyWith<$Res> implements $IosBackgroundConfigCopyWith<$Res> {
  factory _$IosBackgroundConfigCopyWith(_IosBackgroundConfig value, $Res Function(_IosBackgroundConfig) _then) = __$IosBackgroundConfigCopyWithImpl;
@override @useResult
$Res call({
 String restoreIdentifier
});




}
/// @nodoc
class __$IosBackgroundConfigCopyWithImpl<$Res>
    implements _$IosBackgroundConfigCopyWith<$Res> {
  __$IosBackgroundConfigCopyWithImpl(this._self, this._then);

  final _IosBackgroundConfig _self;
  final $Res Function(_IosBackgroundConfig) _then;

/// Create a copy of IosBackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restoreIdentifier = null,}) {
  return _then(_IosBackgroundConfig(
restoreIdentifier: null == restoreIdentifier ? _self.restoreIdentifier : restoreIdentifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AndroidBackgroundConfig {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidBackgroundConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AndroidBackgroundConfig()';
}


}

/// @nodoc
class $AndroidBackgroundConfigCopyWith<$Res>  {
$AndroidBackgroundConfigCopyWith(AndroidBackgroundConfig _, $Res Function(AndroidBackgroundConfig) __);
}


/// Adds pattern-matching-related methods to [AndroidBackgroundConfig].
extension AndroidBackgroundConfigPatterns on AndroidBackgroundConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AndroidForegroundServiceConfig value)?  foregroundService,TResult Function( AndroidCompanionDeviceConfig value)?  companionDevice,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AndroidForegroundServiceConfig() when foregroundService != null:
return foregroundService(_that);case AndroidCompanionDeviceConfig() when companionDevice != null:
return companionDevice(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AndroidForegroundServiceConfig value)  foregroundService,required TResult Function( AndroidCompanionDeviceConfig value)  companionDevice,}){
final _that = this;
switch (_that) {
case AndroidForegroundServiceConfig():
return foregroundService(_that);case AndroidCompanionDeviceConfig():
return companionDevice(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AndroidForegroundServiceConfig value)?  foregroundService,TResult? Function( AndroidCompanionDeviceConfig value)?  companionDevice,}){
final _that = this;
switch (_that) {
case AndroidForegroundServiceConfig() when foregroundService != null:
return foregroundService(_that);case AndroidCompanionDeviceConfig() when companionDevice != null:
return companionDevice(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AndroidNotificationConfig notification)?  foregroundService,TResult Function()?  companionDevice,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AndroidForegroundServiceConfig() when foregroundService != null:
return foregroundService(_that.notification);case AndroidCompanionDeviceConfig() when companionDevice != null:
return companionDevice();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AndroidNotificationConfig notification)  foregroundService,required TResult Function()  companionDevice,}) {final _that = this;
switch (_that) {
case AndroidForegroundServiceConfig():
return foregroundService(_that.notification);case AndroidCompanionDeviceConfig():
return companionDevice();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AndroidNotificationConfig notification)?  foregroundService,TResult? Function()?  companionDevice,}) {final _that = this;
switch (_that) {
case AndroidForegroundServiceConfig() when foregroundService != null:
return foregroundService(_that.notification);case AndroidCompanionDeviceConfig() when companionDevice != null:
return companionDevice();case _:
  return null;

}
}

}

/// @nodoc


class AndroidForegroundServiceConfig implements AndroidBackgroundConfig {
  const AndroidForegroundServiceConfig({required this.notification});


 final  AndroidNotificationConfig notification;

/// Create a copy of AndroidBackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AndroidForegroundServiceConfigCopyWith<AndroidForegroundServiceConfig> get copyWith => _$AndroidForegroundServiceConfigCopyWithImpl<AndroidForegroundServiceConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidForegroundServiceConfig&&(identical(other.notification, notification) || other.notification == notification));
}


@override
int get hashCode => Object.hash(runtimeType,notification);

@override
String toString() {
  return 'AndroidBackgroundConfig.foregroundService(notification: $notification)';
}


}

/// @nodoc
abstract mixin class $AndroidForegroundServiceConfigCopyWith<$Res> implements $AndroidBackgroundConfigCopyWith<$Res> {
  factory $AndroidForegroundServiceConfigCopyWith(AndroidForegroundServiceConfig value, $Res Function(AndroidForegroundServiceConfig) _then) = _$AndroidForegroundServiceConfigCopyWithImpl;
@useResult
$Res call({
 AndroidNotificationConfig notification
});


$AndroidNotificationConfigCopyWith<$Res> get notification;

}
/// @nodoc
class _$AndroidForegroundServiceConfigCopyWithImpl<$Res>
    implements $AndroidForegroundServiceConfigCopyWith<$Res> {
  _$AndroidForegroundServiceConfigCopyWithImpl(this._self, this._then);

  final AndroidForegroundServiceConfig _self;
  final $Res Function(AndroidForegroundServiceConfig) _then;

/// Create a copy of AndroidBackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? notification = null,}) {
  return _then(AndroidForegroundServiceConfig(
notification: null == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as AndroidNotificationConfig,
  ));
}

/// Create a copy of AndroidBackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AndroidNotificationConfigCopyWith<$Res> get notification {

  return $AndroidNotificationConfigCopyWith<$Res>(_self.notification, (value) {
    return _then(_self.copyWith(notification: value));
  });
}
}

/// @nodoc


class AndroidCompanionDeviceConfig implements AndroidBackgroundConfig {
  const AndroidCompanionDeviceConfig();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidCompanionDeviceConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AndroidBackgroundConfig.companionDevice()';
}


}




/// @nodoc
mixin _$AndroidNotificationConfig {

 String get channelId; String get channelName; String get title; String get text;
/// Create a copy of AndroidNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AndroidNotificationConfigCopyWith<AndroidNotificationConfig> get copyWith => _$AndroidNotificationConfigCopyWithImpl<AndroidNotificationConfig>(this as AndroidNotificationConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidNotificationConfig&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,channelId,channelName,title,text);

@override
String toString() {
  return 'AndroidNotificationConfig(channelId: $channelId, channelName: $channelName, title: $title, text: $text)';
}


}

/// @nodoc
abstract mixin class $AndroidNotificationConfigCopyWith<$Res>  {
  factory $AndroidNotificationConfigCopyWith(AndroidNotificationConfig value, $Res Function(AndroidNotificationConfig) _then) = _$AndroidNotificationConfigCopyWithImpl;
@useResult
$Res call({
 String channelId, String channelName, String title, String text
});




}
/// @nodoc
class _$AndroidNotificationConfigCopyWithImpl<$Res>
    implements $AndroidNotificationConfigCopyWith<$Res> {
  _$AndroidNotificationConfigCopyWithImpl(this._self, this._then);

  final AndroidNotificationConfig _self;
  final $Res Function(AndroidNotificationConfig) _then;

/// Create a copy of AndroidNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channelId = null,Object? channelName = null,Object? title = null,Object? text = null,}) {
  return _then(_self.copyWith(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelName: null == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AndroidNotificationConfig].
extension AndroidNotificationConfigPatterns on AndroidNotificationConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AndroidNotificationConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AndroidNotificationConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AndroidNotificationConfig value)  $default,){
final _that = this;
switch (_that) {
case _AndroidNotificationConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AndroidNotificationConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AndroidNotificationConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String channelId,  String channelName,  String title,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AndroidNotificationConfig() when $default != null:
return $default(_that.channelId,_that.channelName,_that.title,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String channelId,  String channelName,  String title,  String text)  $default,) {final _that = this;
switch (_that) {
case _AndroidNotificationConfig():
return $default(_that.channelId,_that.channelName,_that.title,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String channelId,  String channelName,  String title,  String text)?  $default,) {final _that = this;
switch (_that) {
case _AndroidNotificationConfig() when $default != null:
return $default(_that.channelId,_that.channelName,_that.title,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _AndroidNotificationConfig implements AndroidNotificationConfig {
  const _AndroidNotificationConfig({required this.channelId, required this.channelName, required this.title, required this.text});


@override final  String channelId;
@override final  String channelName;
@override final  String title;
@override final  String text;

/// Create a copy of AndroidNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AndroidNotificationConfigCopyWith<_AndroidNotificationConfig> get copyWith => __$AndroidNotificationConfigCopyWithImpl<_AndroidNotificationConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AndroidNotificationConfig&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,channelId,channelName,title,text);

@override
String toString() {
  return 'AndroidNotificationConfig(channelId: $channelId, channelName: $channelName, title: $title, text: $text)';
}


}

/// @nodoc
abstract mixin class _$AndroidNotificationConfigCopyWith<$Res> implements $AndroidNotificationConfigCopyWith<$Res> {
  factory _$AndroidNotificationConfigCopyWith(_AndroidNotificationConfig value, $Res Function(_AndroidNotificationConfig) _then) = __$AndroidNotificationConfigCopyWithImpl;
@override @useResult
$Res call({
 String channelId, String channelName, String title, String text
});




}
/// @nodoc
class __$AndroidNotificationConfigCopyWithImpl<$Res>
    implements _$AndroidNotificationConfigCopyWith<$Res> {
  __$AndroidNotificationConfigCopyWithImpl(this._self, this._then);

  final _AndroidNotificationConfig _self;
  final $Res Function(_AndroidNotificationConfig) _then;

/// Create a copy of AndroidNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channelId = null,Object? channelName = null,Object? title = null,Object? text = null,}) {
  return _then(_AndroidNotificationConfig(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelName: null == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
