package com.example.lumina

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.lumina/video_processor"
    private lateinit var videoProcessor: VideoProcessor
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        videoProcessor = VideoProcessor(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractAudioFromVideo" -> {
                    val videoPath = call.argument<String>("videoPath")
                    val outputPath = call.argument<String>("outputPath")
                    
                    if (videoPath != null && outputPath != null) {
                        val success = videoProcessor.extractAudioFromVideo(videoPath, outputPath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Video path ve output path gerekli", null)
                    }
                }
                "convertToWav" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    
                    if (inputPath != null && outputPath != null) {
                        val success = videoProcessor.convertToWav(inputPath, outputPath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Input path ve output path gerekli", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
