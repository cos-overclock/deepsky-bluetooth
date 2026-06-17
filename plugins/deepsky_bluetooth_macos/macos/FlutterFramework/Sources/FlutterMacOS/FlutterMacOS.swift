import Foundation

// Minimal FlutterMacOS surface used only when this plugin is built with SwiftPM
// for local unit tests. CocoaPods/Flutter builds use the real FlutterMacOS
// framework instead of this package.
public typealias FlutterResult = (Any?) -> Void
public typealias FlutterReply = (Any?) -> Void
public typealias FlutterMessageHandler = (Any?, @escaping FlutterReply) -> Void

public let FlutterMethodNotImplemented = NSObject()

public final class FlutterError: Error {
  public let code: String
  public let message: String?
  public let details: Any?

  public init(code: String, message: String?, details: Any?) {
    self.code = code
    self.message = message
    self.details = details
  }
}

public protocol FlutterBinaryMessenger: AnyObject {}

public protocol FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar)
}

public protocol FlutterPluginRegistrar: AnyObject {
  var messenger: FlutterBinaryMessenger { get }

  func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel)
}

public final class FlutterMethodCall {
  public let method: String
  public let arguments: Any?

  public init(method: String, arguments: Any? = nil) {
    self.method = method
    self.arguments = arguments
  }
}

public final class FlutterMethodChannel {
  public init(name: String, binaryMessenger: FlutterBinaryMessenger) {}
}

public protocol FlutterMessageCodec: AnyObject {}

public class FlutterBasicMessageChannel {
  private var messageHandler: FlutterMessageHandler?

  public init(
    name: String,
    binaryMessenger: FlutterBinaryMessenger,
    codec: FlutterMessageCodec
  ) {}

  public func setMessageHandler(_ handler: FlutterMessageHandler?) {
    messageHandler = handler
  }

  public func sendMessage(_ message: Any?, completion: FlutterReply? = nil) {
    completion?([])
  }
}

public final class FlutterStandardTypedData: NSObject {
  public let data: Data

  public init(bytes data: Data) {
    self.data = data
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? FlutterStandardTypedData else {
      return false
    }
    return data == other.data
  }

  public override var hash: Int {
    data.hashValue
  }
}

open class FlutterStandardReader {
  public init(data: Data) {}

  open func readValue() -> Any? {
    nil
  }

  open func readValue(ofType type: UInt8) -> Any? {
    nil
  }
}

open class FlutterStandardWriter {
  public init(data: NSMutableData) {}

  open func writeByte(_ byte: UInt8) {}

  open func writeValue(_ value: Any) {}
}

open class FlutterStandardReaderWriter {
  public init() {}

  open func reader(with data: Data) -> FlutterStandardReader {
    FlutterStandardReader(data: data)
  }

  open func writer(with data: NSMutableData) -> FlutterStandardWriter {
    FlutterStandardWriter(data: data)
  }
}

open class FlutterStandardMessageCodec: FlutterMessageCodec {
  public let readerWriter: FlutterStandardReaderWriter

  public init(readerWriter: FlutterStandardReaderWriter = FlutterStandardReaderWriter()) {
    self.readerWriter = readerWriter
  }
}
