package com.prashant.dhwani

import android.app.Activity
import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.prashant.dhwani/files"
    private val exportRequestCode = 9129
    private var pendingResult: MethodChannel.Result? = null
    private var pendingSource: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "exportFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("export_busy", "Another export is already open.", null)
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                val source = path?.let(::File)
                if (source == null || !source.isFile || name.isNullOrBlank()) {
                    result.error("missing_file", "The recording file is unavailable.", null)
                    return@setMethodCallHandler
                }
                pendingResult = result
                pendingSource = source
                startActivityForResult(
                    Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = mimeType
                        putExtra(Intent.EXTRA_TITLE, name)
                    },
                    exportRequestCode,
                )
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.prashant.dhwani/installer")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRequestPackageInstalls" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            result.success(packageManager.canRequestPackageInstalls())
                        } else {
                            result.success(true)
                        }
                    }
                    "openInstallPermissionSettings" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    }
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        val file = path?.let(::File)
                        if (file == null || !file.exists()) {
                            result.error("file_not_found", "APK file does not exist", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = androidx.core.content.FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("install_error", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != exportRequestCode) return
        val result = pendingResult
        val source = pendingSource
        pendingResult = null
        pendingSource = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result?.success(false)
            return
        }
        try {
            copyToDocument(source!!, data.data!!)
            result?.success(true)
        } catch (error: Exception) {
            result?.error("export_failed", error.message, null)
        }
    }

    private fun copyToDocument(source: File, destination: Uri) {
        contentResolver.openOutputStream(destination, "w").use { output ->
            requireNotNull(output) { "The chosen location could not be opened." }
            source.inputStream().use { input -> input.copyTo(output) }
        }
    }
}
