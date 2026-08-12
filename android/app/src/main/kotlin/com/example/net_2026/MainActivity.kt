package com.example.net_2026

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Camera
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.zxing.BinaryBitmap
import com.google.zxing.MultiFormatReader
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.common.HybridBinarizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "vinyl/barcode"
        )
        channel = ch

        // Flutter → 네이티브: 권한 확인/요청
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasCameraPermission" -> result.success(
                    ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.CAMERA
                    ) == PackageManager.PERMISSION_GRANTED
                )
                "requestCameraPermission" -> {
                    ActivityCompat.requestPermissions(
                        this, arrayOf(Manifest.permission.CAMERA), 100
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 카메라 뷰 등록 (Flutter의 NativeCameraView가 사용)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "vinyl/barcode-camera",
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, viewId: Int, args: Any?) =
                    BarcodeScannerView(context, ch)
            }
        )
    }

    // 권한 팝업 결과 → Flutter로 전달
    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100) {
            channel?.invokeMethod(
                "onPermissionResult",
                grantResults.isNotEmpty() &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED
            )
        }
    }
}

// 카메라 프리뷰(기본 내장 API) + 바코드 읽기
@Suppress("DEPRECATION")
class BarcodeScannerView(
    context: Context,
    private val channel: MethodChannel,
) : PlatformView, SurfaceHolder.Callback {

    private val surfaceView = SurfaceView(context)
    private val reader = MultiFormatReader()
    private var camera: Camera? = null
    private var frame = 0
    private var found = false

    init {
        surfaceView.holder.addCallback(this)
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        try {
            camera = Camera.open().apply {
                setDisplayOrientation(90) // 세로 화면용
                setPreviewDisplay(holder)
                setPreviewCallback { data, cam ->
                    frame++
                    if (frame % 10 == 0 && !found) { // 10프레임에 1번 스캔
                        val size = cam.parameters.previewSize
                        scan(data, size.width, size.height)
                    }
                }
                startPreview()
            }
        } catch (e: Exception) {
            /* 카메라 권한이 없거나 미지원 디바이스 처리 */
        }
    }

    private fun scan(data: ByteArray, w: Int, h: Int) {
        try {
            val src = PlanarYUVLuminanceSource(
                rotate(data, w, h), h, w, 0, 0, h, w, false
            )
            val code = reader.decodeWithState(
                BinaryBitmap(HybridBinarizer(src))
            ).text
            found = true
            channel.invokeMethod("onBarcode", code) // Flutter로 바코드 전달
        } catch (e: Exception) {
            // 바코드 인식 실패 시 무시하고 다음 프레임 진행
        } finally {
            reader.reset()
        }
    }

    // 카메라 원본 데이터(가로 방향) 90도 회전
    private fun rotate(b: ByteArray, w: Int, h: Int): ByteArray {
        val out = ByteArray(w * h)
        for (y in 0 until h) for (x in 0 until w) out[x * h + (h - 1 - y)] = b[y * w + x]
        return out
    }

    override fun surfaceChanged(h: SurfaceHolder, f: Int, w: Int, hh: Int) {}
    override fun surfaceDestroyed(holder: SurfaceHolder) = dispose()

    override fun getView(): View = surfaceView

    override fun dispose() {
        camera?.apply {
            setPreviewCallback(null)
            stopPreview()
            release()
        }
        camera = null
    }
}