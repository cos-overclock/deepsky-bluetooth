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
mixin _$IosBackgroundConfig {

 String get restoreIdentifier;



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




// dart format on
