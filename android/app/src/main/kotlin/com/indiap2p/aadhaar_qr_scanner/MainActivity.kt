package com.indiap2p.aadhaar_qr_scanner

import android.graphics.Bitmap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import com.gemalto.jp2.JP2Decoder

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.indiap2p.aadhaar_qr_scanner/jp2_decoder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "decodeJp2") {
                val jp2Bytes = call.argument<ByteArray>("bytes")
                if (jp2Bytes == null) {
                    result.error("INVALID_ARGUMENT", "Bytes cannot be null", null)
                    return@setMethodCallHandler
                }

                try {
                    val bitmap = JP2Decoder(jp2Bytes).decode()
                    if (bitmap == null) {
                        result.error("DECODE_FAILED", "Failed to decode JP2 bitmap", null)
                        return@setMethodCallHandler
                    }

                    val outputStream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                    val pngBytes = outputStream.toByteArray()

                    result.success(pngBytes)
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
