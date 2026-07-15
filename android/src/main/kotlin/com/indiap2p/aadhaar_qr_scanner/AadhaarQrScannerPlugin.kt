package com.indiap2p.aadhaar_qr_scanner

import android.graphics.Bitmap
import com.gemalto.jp2.JP2Decoder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/** AadhaarQrScannerPlugin */
class AadhaarQrScannerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.indiap2p.aadhaar_qr_scanner/jp2_decoder")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "decodeJp2" -> {
                val jp2Bytes = call.argument<ByteArray>("bytes")
                if (jp2Bytes == null) {
                    result.error("INVALID_ARGUMENT", "Bytes cannot be null", null)
                    return
                }

                try {
                    val bitmap = JP2Decoder(jp2Bytes).decode()
                    if (bitmap == null) {
                        result.error("DECODE_FAILED", "Failed to decode JP2 bitmap", null)
                        return
                    }

                    val outputStream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                    result.success(outputStream.toByteArray())
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
