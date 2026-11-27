package com.example.spotify

import android.media.audiofx.Equalizer
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

/**
 * The phone's equalizer on the music player's audio session, on the
 * "melodix/equalizer" channel.
 *
 * Kept apart from the player on purpose: just_audio's own equalizer is
 * switched on inside every song load, so when a phone's equalizer misbehaves
 * (seen on a Realme on Android 11) no song can play at all. Here, a failure
 * is only reported back, and the music plays as recorded.
 *
 * One per process (not per activity): the music, and its sound, carry on in
 * the background after the activity is closed.
 */
object NativeEqualizer {
    private const val TAG = "melodix.equalizer"

    private var equalizer: Equalizer? = null
    private var sessionId: Int? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "melodix/equalizer").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "attach" -> result.success(attach(call.argument<Int>("sessionId")!!))
                    "setEnabled" -> {
                        equalizer?.setEnabled(call.argument<Boolean>("enabled")!!)
                        result.success(null)
                    }
                    "setGains" -> {
                        setGains(call.argument<List<Double>>("gains")!!)
                        result.success(null)
                    }
                    "release" -> {
                        release()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                // Never fatal: the caller carries on without the equalizer.
                Log.w(TAG, "${call.method} failed", e)
                result.error("equalizer_failed", e.toString(), null)
            }
        }
    }

    /**
     * An equalizer on audio session [id] (a new one if the session changed),
     * and its bands: centre frequencies in Hz, and the gain range in dB.
     */
    private fun attach(id: Int): Map<String, Any> {
        if (equalizer == null || sessionId != id) {
            release()
            try {
                equalizer = Equalizer(0, id)
                sessionId = id
            } catch (e: Throwable) {
                release()
                throw e
            }
        }
        val eq = equalizer!!
        val range = eq.bandLevelRange
        return mapOf(
            "centers" to (0 until eq.numberOfBands).map { band ->
                eq.getCenterFreq(band.toShort()) / 1000.0 // milliHertz → Hz
            },
            "minDb" to range[0] / 100.0, // milliBel → dB
            "maxDb" to range[1] / 100.0,
        )
    }

    /** dB for each band, in band order. */
    private fun setGains(gains: List<Double>) {
        val eq = equalizer ?: return
        val bands = minOf(gains.size, eq.numberOfBands.toInt())
        for (band in 0 until bands) {
            eq.setBandLevel(band.toShort(), (gains[band] * 100).roundToInt().toShort())
        }
    }

    private fun release() {
        try {
            equalizer?.release()
        } catch (e: Throwable) {
            Log.w(TAG, "release failed", e)
        }
        equalizer = null
        sessionId = null
    }
}
