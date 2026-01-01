package com.velocitylink.intune

import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ACCESSIBILITY_CHANNEL = "com.velocitylink.intune/accessibility"
    private val STATS_CHANNEL = "com.velocitylink.intune/device_stats"
    private val COMMANDS_CHANNEL = "com.velocitylink.intune/commands"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Accessibility Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isServiceEnabled" -> {
                    result.success(VelocityAccessibilityService.isServiceEnabled())
                }
                "openSettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(null)
                }
                "tap" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val success = VelocityAccessibilityService.performTap(x, y)
                    result.success(success)
                }
                "swipe" -> {
                    val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                    val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                    val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                    val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration")?.toLong() ?: 300L
                    
                    val success = VelocityAccessibilityService.performSwipe(startX, startY, endX, endY, duration)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
        
        // Device Stats Channel (Placeholder - handled by Dart packages mostly)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STATS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceStats") {
                // We are using Dart packages for this now, but keeping this for potential native extensions
                result.notImplemented()
            } else {
                result.notImplemented()
            }
        }
        
        // Commands Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMMANDS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "stopRing") {
                // Stop any native ringing if implemented
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
