package com.example.deepsky_bluetooth_android

import android.util.Log
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean

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
        if (!Log.isLoggable(TAG, Log.DEBUG)) return
        Log.d(TAG, "method start: $method ${payload.toLogSuffix()}")
    }

    override fun onMethodEnd(method: String, payload: Map<String, Any?>, errorCode: String?) {
        if (!Log.isLoggable(TAG, Log.DEBUG)) return
        val status = errorCode ?: "ok"
        Log.d(TAG, "method end: $method status=$status ${payload.toLogSuffix()}")
    }

    override fun onCallback(callback: String, payload: Map<String, Any?>) {
        if (!Log.isLoggable(TAG, Log.DEBUG)) return
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
        resetToDefaults()
    }

    fun register(observer: BleNativeObserver) {
        observers.addIfAbsent(observer)
    }

    fun unregister(observer: BleNativeObserver) {
        observers.remove(observer)
    }

    fun clear() {
        resetToDefaults()
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

    fun <T> observeCallbackMethod(
        method: String,
        payload: Map<String, Any?> = emptyMap(),
        callback: (Result<T>) -> Unit,
        block: ((Result<T>) -> Unit) -> Unit,
    ) {
        emitMethodStart(method, payload)
        val completed = AtomicBoolean(false)
        val observedCallback: (Result<T>) -> Unit = { result ->
            if (completed.compareAndSet(false, true)) {
                emitMethodEnd(method, payload, result.exceptionOrNull()?.pigeonCodeOrNull())
            }
            callback(result)
        }
        try {
            block(observedCallback)
        } catch (error: Throwable) {
            if (completed.compareAndSet(false, true)) {
                emitMethodEnd(method, payload, error.pigeonCodeOrNull())
            }
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

    private fun resetToDefaults() {
        observers.clear()
        observers.add(LogcatBleNativeObserver)
    }
}

internal fun Throwable.pigeonCodeOrNull(): String? = (this as? FlutterError)?.code
