package com.example.deepsky_bluetooth_android

/** Dart 側 sealed error へ対応させる安定したエラーコード文字列。 */
object BleErrorCode {
    const val PERMISSION_DENIED = "permissionDenied"
    const val BLUETOOTH_OFF = "bluetoothOff"
    const val BLUETOOTH_UNAVAILABLE = "bluetoothUnavailable"
    const val ALREADY_SCANNING = "alreadyScanning"
    const val NOT_FOUND = "notFound"
    const val NOT_CONNECTED = "notConnected"
    const val NOT_SUPPORTED = "notSupported"
    const val BUFFER_FULL = "bufferFull"
    const val READ_AMBIGUOUS_WHILE_NOTIFYING = "readAmbiguousWhileNotifying"
    const val TIMEOUT = "timeout"
    const val REJECTED = "rejected"
    const val ALREADY_INITIALIZED = "alreadyInitialized"
    const val BACKGROUND_CONFIG_MISSING = "backgroundConfigMissing"
    const val NOT_ASSOCIATED = "notAssociated"
    const val FAILED = "failed"
}

/** [FlutterError] は Pigeon 生成の `Messages.g.kt` に定義される。 */
fun bleError(code: String, message: String): FlutterError =
    FlutterError(code, message, null)
