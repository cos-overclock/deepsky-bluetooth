package com.example.deepsky_bluetooth_android.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class DeviceAddressNormalizerTest {

    @Test
    fun normalize_upcasesLowercaseMacAddress() {
        // MacAddress.toString() は小文字。正準形は大文字 MAC に揃える(既存 deviceId 表現)。
        assertEquals(
            "AA:BB:CC:DD:EE:FF",
            DeviceAddressNormalizer.normalize("aa:bb:cc:dd:ee:ff"),
        )
    }

    @Test
    fun normalize_keepsAlreadyCanonicalAddress() {
        assertEquals(
            "12:34:56:78:9A:BC",
            DeviceAddressNormalizer.normalize("12:34:56:78:9A:BC"),
        )
    }

    @Test
    fun normalize_trimsSurroundingWhitespace() {
        assertEquals(
            "00:11:22:33:44:55",
            DeviceAddressNormalizer.normalize("  00:11:22:33:44:55  "),
        )
    }

    @Test
    fun normalize_returnsNullForNullInput() {
        assertNull(DeviceAddressNormalizer.normalize(null))
    }

    @Test
    fun normalize_returnsNullForWrongOctetCount() {
        assertNull(DeviceAddressNormalizer.normalize("aa:bb:cc:dd:ee"))
        assertNull(DeviceAddressNormalizer.normalize("aa:bb:cc:dd:ee:ff:00"))
    }

    @Test
    fun normalize_returnsNullForNonHexDigits() {
        assertNull(DeviceAddressNormalizer.normalize("zz:bb:cc:dd:ee:ff"))
    }

    @Test
    fun normalize_returnsNullForMalformedSeparatorsOrLength() {
        assertNull(DeviceAddressNormalizer.normalize("aabbccddeeff"))
        assertNull(DeviceAddressNormalizer.normalize("a:bb:cc:dd:ee:ff"))
        assertNull(DeviceAddressNormalizer.normalize(""))
    }
}
