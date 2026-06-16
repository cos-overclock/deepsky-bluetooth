package com.example.deepsky_bluetooth_android

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * 各 Flutter engine に attach する plugin instance。
 *
 * BLE 接続・接続 epoch・scan はプロセスグローバルな [BleProcessOwner] が保持し、本 plugin は
 * messenger sink を提供して [BleHostApi] を配線するだけ。engine detach では sink を解除する
 * のみで接続は保持する(Review guide §12)。
 */
class DeepskyBluetoothAndroidPlugin : FlutterPlugin {
    private var callbacks: BleCallbacksApi? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        BleNativeObservers.observeMethod("plugin.attach") {
            BleProcessOwner.attach(binding.applicationContext)
            val cb = BleCallbacksApi(binding.binaryMessenger)
            BleProcessOwner.registerSink(cb)
            callbacks = cb
            BleHostApi.setUp(binding.binaryMessenger, BleCentralManager(binding.applicationContext))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        BleNativeObservers.observeMethod("plugin.detach") {
            BleHostApi.setUp(binding.binaryMessenger, null)
            // engine 固有 sink だけを解除。接続・scan・epoch は owner が保持し続ける(close しない)。
            callbacks?.let { BleProcessOwner.unregisterSink(it) }
            callbacks = null
        }
    }
}
