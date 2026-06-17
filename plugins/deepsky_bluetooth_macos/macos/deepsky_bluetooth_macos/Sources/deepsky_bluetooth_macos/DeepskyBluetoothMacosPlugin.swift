import Cocoa
import FlutterMacOS

public class DeepskyBluetoothMacosPlugin: NSObject, FlutterPlugin {
  private let engineToken: String
  private let owner: MacosBleProcessOwner

  init(engineToken: String = UUID().uuidString, owner: MacosBleProcessOwner = .shared) {
    self.engineToken = engineToken
    self.owner = owner
    super.init()
  }

  deinit {
    owner.unregisterSink(engineToken: engineToken)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "deepsky_bluetooth_macos", binaryMessenger: registrar.messenger)
    let instance = DeepskyBluetoothMacosPlugin()
    let callbacks = BleCallbacksApi(binaryMessenger: registrar.messenger)
    instance.owner.registerSink(engineToken: instance.engineToken, callbacks: callbacks)
    BleHostApiSetup.setUp(
      binaryMessenger: registrar.messenger,
      api: MacosBleHostApi(engineToken: instance.engineToken, owner: instance.owner)
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
