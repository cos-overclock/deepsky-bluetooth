import Foundation

enum BleErrorCode {
  static let bluetoothOff = "bluetoothOff"
  static let bluetoothUnavailable = "bluetoothUnavailable"
  static let alreadyScanning = "alreadyScanning"
  static let notFound = "notFound"
  static let notConnected = "notConnected"
  static let notSupported = "notSupported"
  static let failed = "failed"
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
}
