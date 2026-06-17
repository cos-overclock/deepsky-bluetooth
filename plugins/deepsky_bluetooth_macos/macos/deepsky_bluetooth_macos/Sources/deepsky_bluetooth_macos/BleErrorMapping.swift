import Foundation

enum BleErrorCode {
  static let permissionDenied = "permissionDenied"
  static let bluetoothOff = "bluetoothOff"
  static let bluetoothUnavailable = "bluetoothUnavailable"
  static let alreadyScanning = "alreadyScanning"
  static let notFound = "notFound"
  static let notConnected = "notConnected"
  static let notSupported = "notSupported"
  static let failed = "failed"
  static let readAmbiguousWhileNotifying = "readAmbiguousWhileNotifying"
  static let bufferFull = "bufferFull"
  static let operationTimeout = "operationTimeout"
}

func bleError(_ code: String, _ message: String) -> PigeonError {
  PigeonError(code: code, message: message, details: nil)
}

enum BleErrorMapping {
  static func bluetoothOff() -> PigeonError {
    bleError(BleErrorCode.bluetoothOff, "Bluetooth is off")
  }

  static func bluetoothUnavailable(_ message: String) -> PigeonError {
    bleError(BleErrorCode.bluetoothUnavailable, message)
  }

  static func permissionDenied(_ message: String = "Bluetooth permission denied") -> PigeonError {
    bleError(BleErrorCode.permissionDenied, message)
  }

  static func alreadyScanning() -> PigeonError {
    bleError(BleErrorCode.alreadyScanning, "Scan already running")
  }

  static func notFound(_ message: String) -> PigeonError {
    bleError(BleErrorCode.notFound, message)
  }

  static func notConnected() -> PigeonError {
    bleError(BleErrorCode.notConnected, "Not connected")
  }

  static func notSupported(_ message: String) -> PigeonError {
    bleError(BleErrorCode.notSupported, message)
  }

  static func failed(_ message: String) -> PigeonError {
    bleError(BleErrorCode.failed, message)
  }

  static func readAmbiguousWhileNotifying() -> PigeonError {
    bleError(BleErrorCode.readAmbiguousWhileNotifying,
             "read(strictRead: true) is ambiguous while notifying")
  }

  static func bufferFull() -> PigeonError {
    bleError(BleErrorCode.bufferFull, "Write without response buffer is full")
  }

  static func operationTimeout() -> PigeonError {
    bleError(BleErrorCode.operationTimeout, "GATT operation timed out")
  }
}
