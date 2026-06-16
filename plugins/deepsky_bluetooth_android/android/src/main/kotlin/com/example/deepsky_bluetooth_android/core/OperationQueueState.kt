package com.example.deepsky_bluetooth_android.core

/**
 * device(= 1 接続 = 1 `connectionEpoch`)単位の GATT 操作 FIFO queue を表す状態機械。
 *
 * - 同時に実行できる操作は先頭の1件だけとし、要求と応答を FIFO で一意に相関させる。
 * - 各操作は探索/read/write/descriptor/setNotify(CCCD write)/MTU/RSSI のいずれかで、
 *   接続内で単調増加する [QueuedOperation.opSeq] を採番する。
 * - callback は現行 [epoch] と先頭操作の種別が一致した場合だけ先頭を完了させる。遅延・想定外の
 *   callback は先頭を据え置いて無視し、次操作を誤完了しない(Review guide §10)。
 * - timeout などで [retire] すると queue は終端になり、以後 startNext / completeCurrent は何も
 *   進めない。これにより「同じ接続(=同じ GATT)で処理を続行しない」を構造的に保証する。
 *
 * Bluetooth API へ一切依存しない pure state machine とし、FIFO 直列化・callback 相関・timeout
 * 退役の契約を local JVM test だけで検証できる(Review guide §10 / §16)。実際の `BluetoothGatt`
 * 呼び出し・watchdog timer・main thread への post は呼び出し側([GattConnection])が担い、本クラスは
 * 「次に何を実行/完了/破棄するか」だけを決める。[QueuedOperation.payload] に completer 等を載せる。
 */
class OperationQueueState<T>(val epoch: Long) {
    private val pending = ArrayDeque<QueuedOperation<T>>()
    private var inFlight: QueuedOperation<T>? = null
    private var nextOpSeq = FIRST_OP_SEQ

    /** [retire] 済みなら true。終端状態で、以後 enqueue は失敗し操作は進まない。 */
    var isRetired = false
        private set

    /** 現在 in-flight の先頭操作。実行中の操作が無ければ null。 */
    val current: QueuedOperation<T>? get() = inFlight

    /** 先頭操作が実行中(= 次を実行できない)か。 */
    val isBusy: Boolean get() = inFlight != null

    /** まだ実行を開始していない待機操作の件数。 */
    val pendingCount: Int get() = pending.size

    /**
     * [kind] の操作を queue 末尾へ追加し、接続内 opSeq を採番した [QueuedOperation] を返す。
     * 退役後の enqueue は呼び出し側の不変条件違反として [IllegalStateException]。
     */
    fun enqueue(kind: OperationKind, payload: T): QueuedOperation<T> {
        check(!isRetired) { "Cannot enqueue on a retired operation queue" }
        val op = QueuedOperation(epoch, nextOpSeq++, kind, payload)
        pending.addLast(op)
        return op
    }

    /**
     * 実行可能なら次の先頭操作を取り出して in-flight にし、それを返す。既に in-flight がある
     * (同時1操作)・queue が空・退役済みのいずれかなら null。返した操作は呼び出し側が実行する。
     */
    fun startNext(): QueuedOperation<T>? {
        if (isRetired || inFlight != null) return null
        val op = pending.removeFirstOrNull() ?: return null
        inFlight = op
        return op
    }

    /**
     * 到着した callback で先頭操作を完了する。[callbackEpoch] が現行 [epoch] と一致し、かつ
     * 先頭操作の種別が [callbackKind] と整合する場合だけ先頭を取り外して返す。一致しなければ
     * (遅延・旧 epoch・想定外 callback)先頭を据え置き null を返す。退役後も null。
     */
    fun completeCurrent(callbackEpoch: Long, callbackKind: CallbackKind): QueuedOperation<T>? {
        if (isRetired) return null
        val op = inFlight ?: return null
        if (callbackEpoch != epoch) return null
        if (op.kind.callbackKind != callbackKind) return null
        inFlight = null
        return op
    }

    /**
     * 実行を開始できなかった先頭操作を取り外して返す(呼び出し側が失敗完了させる)。in-flight が
     * 無ければ null。取り外し後は [startNext] で次操作を実行できる。
     */
    fun abortCurrent(): QueuedOperation<T>? {
        val op = inFlight ?: return null
        inFlight = null
        return op
    }

    /**
     * queue を終端化し、in-flight → pending の順で未完了操作を全て返す(呼び出し側が timeout 系
     * エラーで完了させる)。以後この queue では何も実行・完了しない。冪等で、2回目以降は空を返す。
     */
    fun retire(): List<QueuedOperation<T>> {
        if (isRetired) return emptyList()
        isRetired = true
        val drained = buildList {
            inFlight?.let { add(it) }
            addAll(pending)
        }
        inFlight = null
        pending.clear()
        return drained
    }

    companion object {
        /** 最初に採番する opSeq。0 を「未採番」と区別するため 1 から始める。 */
        const val FIRST_OP_SEQ = 1L
    }
}

/**
 * queue に載る GATT 操作1件。[epoch] と [opSeq] で接続内の操作を一意に識別し、[payload] に
 * 呼び出し側の completer や native object 参照を載せる。
 */
data class QueuedOperation<T>(
    val epoch: Long,
    val opSeq: Long,
    val kind: OperationKind,
    val payload: T,
)

/**
 * FIFO queue に載せて直列化する GATT 操作の種別。notify/indicate(`onCharacteristicChanged`)は
 * 要求応答ではないため queue に載せず、ここには含めない(Review guide §10)。
 *
 * [callbackKind] は完了を引き起こす GATT callback の種別。setNotify は CCCD descriptor write の
 * ため [CallbackKind.DESCRIPTOR_WRITE] で完了する。
 */
enum class OperationKind(val callbackKind: CallbackKind) {
    DISCOVER_SERVICES(CallbackKind.SERVICES_DISCOVERED),
    READ_CHARACTERISTIC(CallbackKind.CHARACTERISTIC_READ),
    WRITE_CHARACTERISTIC(CallbackKind.CHARACTERISTIC_WRITE),
    READ_DESCRIPTOR(CallbackKind.DESCRIPTOR_READ),
    WRITE_DESCRIPTOR(CallbackKind.DESCRIPTOR_WRITE),
    SET_NOTIFY(CallbackKind.DESCRIPTOR_WRITE),
    REQUEST_MTU(CallbackKind.MTU_CHANGED),
    READ_RSSI(CallbackKind.RSSI_READ),
}

/** 先頭操作の完了を引き起こす GATT callback の種別。 */
enum class CallbackKind {
    SERVICES_DISCOVERED,
    CHARACTERISTIC_READ,
    CHARACTERISTIC_WRITE,
    DESCRIPTOR_READ,
    DESCRIPTOR_WRITE,
    MTU_CHANGED,
    RSSI_READ,
}
