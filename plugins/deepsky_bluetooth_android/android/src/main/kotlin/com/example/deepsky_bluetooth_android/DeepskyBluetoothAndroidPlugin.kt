package com.example.deepsky_bluetooth_android

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

/**
 * 各 Flutter engine に attach する plugin instance。
 *
 * BLE 接続・接続 epoch・scan はプロセスグローバルな [BleProcessOwner] が保持し、本 plugin は
 * messenger sink を提供して [BleHostApi] を配線するだけ。engine detach では sink を解除する
 * のみで接続は保持する(Review guide §12)。
 *
 * Companion Device の associate はシステムのペアリング選択ダイアログを Activity 上で起動する
 * 必要があるため [ActivityAware] を実装し、Activity と [PluginRegistry.ActivityResultListener]
 * を owner へ供給する。Activity 解除でも接続・epoch は owner が保持し続ける。
 */
class DeepskyBluetoothAndroidPlugin :
    FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {

    private var callbacks: BleCallbacksApi? = null
    private var activityBinding: ActivityPluginBinding? = null

    // Whether this engine's plugin instance ever attached to an Activity. A headless relaunch
    // engine never does, so this distinguishes UI vs headless engines on detach (#28).
    private var wasUiEngine = false
    private var appContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        BleNativeObservers.observeMethod("plugin.attach") {
            appContext = binding.applicationContext
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
            // Report the detach so the launcher can relaunch a headless engine when a UI engine is
            // lost while the Foreground Service runs (#28). A headless engine never attached to an
            // Activity, so wasUiEngine distinguishes the two.
            appContext?.let { HeadlessEngineLauncher.onEngineDetached(it, isHeadless = !wasUiEngine) }
        }
    }

    // --- ActivityAware ---------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = bindActivity(binding)

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        bindActivity(binding)

    override fun onDetachedFromActivity() = unbindActivity()

    override fun onDetachedFromActivityForConfigChanges() = unbindActivity()

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean =
        BleProcessOwner.handleCompanionActivityResult(requestCode, resultCode, data)

    private fun bindActivity(binding: ActivityPluginBinding) {
        BleNativeObservers.observeMethod("plugin.attachActivity") {
            activityBinding?.removeActivityResultListener(this)
            activityBinding = binding
            binding.addActivityResultListener(this)
            BleProcessOwner.setActivity(binding.activity)
            // This engine drives UI; mark it so a later detach is treated as a UI (not headless)
            // loss, and let the launcher hold any headless engine until the handover ack (#28).
            wasUiEngine = true
            HeadlessEngineLauncher.onUiEngineCandidateAttached()
        }
    }

    private fun unbindActivity() {
        BleNativeObservers.observeMethod("plugin.detachActivity") {
            activityBinding?.removeActivityResultListener(this)
            activityBinding = null
            BleProcessOwner.setActivity(null)
        }
    }
}
