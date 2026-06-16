package com.example.deepsky_bluetooth_android.core

/**
 * 1 接続 epoch 内で探索した GATT 属性に整数 handle を採番し、handle から native object への
 * 逆引きを提供する。
 *
 * - handle は探索順に単調増加で採番する。同じ UUID の属性が複数あっても別 handle になるため、
 *   UUID ではなく handle で操作・通知を相関できる(Review guide §9)。
 * - [handleOf] で native object → handle の逆引きも提供する。notify/indicate callback で来た
 *   characteristic instance から handle を引き、通知ストリームへ相関させるために使う。逆引きは
 *   identity(参照同一性)で照合し、同じ UUID の別 instance を取り違えない(Review guide §9)。
 * - epoch 退役・再探索時は [clear] で全 mapping を破棄する。counter は戻さないため、古い tree の
 *   handle は再探索後も new object へ付け替わらず解決不能のままになる(Review guide §11)。
 *
 * Android framework へ依存しない汎用 registry とし、local JVM test だけで採番・逆引き・clear の
 * 契約を検証できる(Review guide §16)。native object の Android 型への cast は呼び出し側で行う。
 */
class HandleRegistry<T> {
    private val objects = mutableMapOf<Long, T>()
    // 逆引きは identity 照合。equals が等しい別 instance(同 UUID の属性)を別 handle として扱う。
    private val handlesByObject = java.util.IdentityHashMap<T, Long>()
    private var nextHandle = FIRST_HANDLE

    /** [value] に探索順の新しい handle を採番して登録し、その handle を返す。 */
    @Synchronized
    fun register(value: T): Long {
        val handle = nextHandle++
        objects[handle] = value
        handlesByObject[value] = handle
        return handle
    }

    /** [handle] に対応する native object。未登録・clear 済みなら null(呼び出し側で NotFound)。 */
    @Synchronized
    fun resolve(handle: Long): T? = objects[handle]

    /** [value] と参照同一な登録済み object の handle。未登録・clear 済みなら null。 */
    @Synchronized
    fun handleOf(value: T): Long? = handlesByObject[value]

    /** [handle] が現在有効に登録されているか。 */
    @Synchronized
    fun contains(handle: Long): Boolean = objects.containsKey(handle)

    /** 全 mapping を破棄する。counter は戻さないため古い handle は二度と解決できない。 */
    @Synchronized
    fun clear() {
        objects.clear()
        handlesByObject.clear()
    }

    companion object {
        /** 最初に採番する handle。0 は「未採番」と区別するため 1 から始める。 */
        const val FIRST_HANDLE = 1L
    }
}
