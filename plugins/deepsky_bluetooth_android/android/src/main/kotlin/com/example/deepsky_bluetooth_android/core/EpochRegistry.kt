package com.example.deepsky_bluetooth_android.core

/**
 * プロセスグローバル native owner が払い出す device 単位の接続世代(epoch)を管理する。
 *
 * - epoch は device ごとに単調増加する整数で、新しい接続実体を生成するたびに採番する。
 * - retire した接続の epoch は二度と current にならず、古い callback を guard で破棄できる。
 *
 * Bluetooth API へ一切依存しないため、local JVM test だけで全契約を検証できる
 * (Review guide §9 / §16)。
 */
class EpochRegistry {
    /** device ごとに最後に払い出した epoch。retire しても減らさない(単調増加の保証)。 */
    private val lastIssued = mutableMapOf<String, Long>()

    /** device ごとに現在有効な epoch。retire で消える。 */
    private val current = mutableMapOf<String, Long>()

    /** [deviceId] に対し単調増加する新しい epoch を採番し、current にする。 */
    @Synchronized
    fun allocate(deviceId: String): Long {
        val next = (lastIssued[deviceId] ?: 0L) + 1L
        lastIssued[deviceId] = next
        current[deviceId] = next
        return next
    }

    /** [deviceId] の現在 epoch。未採番または retire 済みなら null。 */
    @Synchronized
    fun current(deviceId: String): Long? = current[deviceId]

    /** [epoch] が [deviceId] の現在 epoch と一致する場合だけ true。古い epoch は false。 */
    @Synchronized
    fun isCurrent(deviceId: String, epoch: Long): Boolean = current[deviceId] == epoch

    /** [deviceId] の現在 epoch を退役させ、どの epoch も current でない状態にする。 */
    @Synchronized
    fun retire(deviceId: String) {
        current.remove(deviceId)
    }
}
