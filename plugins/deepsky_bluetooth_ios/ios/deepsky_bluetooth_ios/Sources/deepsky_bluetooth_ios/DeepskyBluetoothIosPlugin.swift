import Flutter
import UIKit

public class DeepskyBluetoothIosPlugin: NSObject, FlutterPlugin {
  private let engineToken: String
  private let owner: IosBleProcessOwner

  init(engineToken: String = UUID().uuidString, owner: IosBleProcessOwner = .shared) {
    self.engineToken = engineToken
    self.owner = owner
    super.init()
  }

  deinit {
    owner.unregisterSink(engineToken: engineToken)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "deepsky_bluetooth_ios", binaryMessenger: registrar.messenger())
    let instance = DeepskyBluetoothIosPlugin()
    let callbacks = BleCallbacksApi(binaryMessenger: registrar.messenger())
    instance.owner.registerSink(engineToken: instance.engineToken, callbacks: callbacks)
    BleHostApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: IosBleHostApi(engineToken: instance.engineToken, owner: instance.owner)
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
