package com.example.deepsky_bluetooth_android

import android.util.Log
import java.util.concurrent.CopyOnWriteArrayList

/** Android native layer lifecycle/callback observer. */
internal interface BleNativeObserver {
    fun onMethodStart(method: String, payload: Map<String, Any?> = emptyMap()) {}

    fun onMethodEnd(
        method: String,
        payload: Map<String, Any?> = emptyMap(),
        errorCode: String? = null,
    ) {}

    fun onCallback(callback: String, payload: Map<String, Any?> = emptyMap()) {}
}

/** Default observer that writes native diagnostics to Logcat. */
internal object LogcatBleNativeObserver : BleNativeObserver {
    private const val TAG = "DeepskyBluetooth"

    override fun onMethodStart(method: String, payload: Map<String, Any?>) {
        Log.d(TAG, "method start: $method ${payload.toLogSuffix()}")
    }

    override fun onMethodEnd(method: String, payload: Map<String, Any?>, errorCode: String?) {
        val status = errorCode ?: "ok"
        Log.d(TAG, "method end: $method status=$status ${payload.toLogSuffix()}")
    }

    override fun onCallback(callback: String, payload: Map<String, Any?>) {
        Log.d(TAG, "callback: $callback ${payload.toLogSuffix()}")
    }

    private fun Map<String, Any?>.toLogSuffix(): String =
        if (isEmpty()) "" else entries.joinToString(prefix = "{", postfix = "}") {
            "${it.key}=${it.value}"
        }
}

/** Process-wide native observer registry. Observer failures never affect BLE behavior. */
internal object BleNativeObservers {
    private val observers = CopyOnWriteArrayList<BleNativeObserver>()

    init {
        register(LogcatBleNativeObserver)
    }

    fun register(observer: BleNativeObserver) {
        observers.addIfAbsent(observer)
    }

    fun unregister(observer: BleNativeObserver) {
        observers.remove(observer)
    }

    fun clear() {
        observers.clear()
    }

    fun <T> observeMethod(
        method: String,
        payload: Map<String, Any?> = emptyMap(),
        block: () -> T,
    ): T {
        emitMethodStart(method, payload)
        return try {
            val result = block()
            emitMethodEnd(method, payload, null)
            result
        } catch (error: Throwable) {
            emitMethodEnd(method, payload, error.pigeonCodeOrNull())
            throw error
        }
    }

    fun emitCallback(callback: String, payload: Map<String, Any?> = emptyMap()) {
        observers.forEachSafely { it.onCallback(callback, payload) }
    }

    fun emitMethodStart(method: String, payload: Map<String, Any?> = emptyMap()) {
        observers.forEachSafely { it.onMethodStart(method, payload) }
    }

    fun emitMethodEnd(
        method: String,
        payload: Map<String, Any?> = emptyMap(),
        errorCode: String? = null,
    ) {
        observers.forEachSafely { it.onMethodEnd(method, payload, errorCode) }
    }

    private inline fun CopyOnWriteArrayList<BleNativeObserver>.forEachSafely(
        action: (BleNativeObserver) -> Unit,
    ) {
        forEach {
            try {
                action(it)
            } catch (_: Throwable) {
                // Observers are diagnostics only.
            }
        }
    }
}

private fun Throwable.pigeonCodeOrNull(): String? = (this as? FlutterError)?.code
