package com.velocitylink.intune

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * VelocityLink Accessibility Service
 * 
 * This service allows the Windows PC to remotely control the Android device
 * by performing gestures (taps, swipes, etc.) on the screen.
 * 
 * IMPORTANT: The user must manually enable this service in Settings > Accessibility
 */
class VelocityAccessibilityService : AccessibilityService() {
    
    companion object {
        var instance: VelocityAccessibilityService? = null
        private const val TAG = "VelocityAccessibility"
        
        /**
         * Check if service is running
         */
        fun isServiceEnabled(): Boolean = instance != null
        
        /**
         * Perform a tap at given screen coordinates
         */
        fun performTap(x: Float, y: Float): Boolean {
            return instance?.doTap(x, y) ?: false
        }
        
        /**
         * Perform a swipe gesture
         */
        fun performSwipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long = 300): Boolean {
            return instance?.doSwipe(startX, startY, endX, endY, duration) ?: false
        }
        
        /**
         * Perform a long press
         */
        fun performLongPress(x: Float, y: Float): Boolean {
            return instance?.doLongPress(x, y) ?: false
        }
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        android.util.Log.d(TAG, "✅ VelocityAccessibilityService connected")
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for gesture injection
    }
    
    override fun onInterrupt() {
        android.util.Log.d(TAG, "⚠️ VelocityAccessibilityService interrupted")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        android.util.Log.d(TAG, "🛑 VelocityAccessibilityService destroyed")
    }
    
    /**
     * Perform a tap gesture at the given screen coordinates
     */
    private fun doTap(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            android.util.Log.e(TAG, "❌ Gestures require Android 7.0+")
            return false
        }
        
        try {
            val path = Path()
            path.moveTo(x, y)
            
            val gestureBuilder = GestureDescription.Builder()
            gestureBuilder.addStroke(
                GestureDescription.StrokeDescription(path, 0, 100)
            )
            
            val result = dispatchGesture(gestureBuilder.build(), object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    android.util.Log.d(TAG, "✅ Tap completed at ($x, $y)")
                }
                
                override fun onCancelled(gestureDescription: GestureDescription?) {
                    android.util.Log.w(TAG, "⚠️ Tap cancelled at ($x, $y)")
                }
            }, null)
            
            return result
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Tap failed: ${e.message}")
            return false
        }
    }
    
    /**
     * Perform a swipe gesture from one point to another
     */
    private fun doSwipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return false
        }
        
        try {
            val path = Path()
            path.moveTo(startX, startY)
            path.lineTo(endX, endY)
            
            val gestureBuilder = GestureDescription.Builder()
            gestureBuilder.addStroke(
                GestureDescription.StrokeDescription(path, 0, duration)
            )
            
            val result = dispatchGesture(gestureBuilder.build(), object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    android.util.Log.d(TAG, "✅ Swipe completed")
                }
                
                override fun onCancelled(gestureDescription: GestureDescription?) {
                    android.util.Log.w(TAG, "⚠️ Swipe cancelled")
                }
            }, null)
            
            return result
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Swipe failed: ${e.message}")
            return false
        }
    }
    
    /**
     * Perform a long press at the given coordinates
     */
    private fun doLongPress(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return false
        }
        
        try {
            val path = Path()
            path.moveTo(x, y)
            
            val gestureBuilder = GestureDescription.Builder()
            // Long press is a tap that lasts 1000ms
            gestureBuilder.addStroke(
                GestureDescription.StrokeDescription(path, 0, 1000)
            )
            
            return dispatchGesture(gestureBuilder.build(), null, null)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Long press failed: ${e.message}")
            return false
        }
    }
}
