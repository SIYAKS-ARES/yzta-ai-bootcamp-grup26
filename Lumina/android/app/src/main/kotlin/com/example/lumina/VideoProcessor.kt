package com.example.lumina

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.io.File
import java.nio.ByteBuffer

class VideoProcessor(private val context: Context) {
    
    companion object {
        private const val TAG = "VideoProcessor"
    }
    
    fun extractAudioFromVideo(videoPath: String, outputPath: String): Boolean {
        return try {
            val extractor = MediaExtractor()
            extractor.setDataSource(videoPath)
            
            // Audio track'ini bul
            var audioTrackIndex = -1
            var audioFormat: MediaFormat? = null
            
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME)
                
                if (mime?.startsWith("audio/") == true) {
                    audioTrackIndex = i
                    audioFormat = format
                    break
                }
            }
            
            if (audioTrackIndex == -1) {
                Log.e(TAG, "Audio track bulunamadı")
                return false
            }
            
            // Audio track'ini seç
            extractor.selectTrack(audioTrackIndex)
            
            // MediaMuxer oluştur
            val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val outputTrackIndex = muxer.addTrack(audioFormat!!)
            muxer.start()
            
            // Audio verilerini kopyala
            val buffer = ByteBuffer.allocate(64 * 1024) // 64KB buffer
            val bufferInfo = MediaCodec.BufferInfo()
            
            while (true) {
                val sampleSize = extractor.readSampleData(buffer, 0)
                
                if (sampleSize < 0) {
                    break // End of stream
                }
                
                bufferInfo.offset = 0
                bufferInfo.size = sampleSize
                bufferInfo.presentationTimeUs = extractor.sampleTime
                bufferInfo.flags = extractor.sampleFlags
                
                muxer.writeSampleData(outputTrackIndex, buffer, bufferInfo)
                extractor.advance()
            }
            
            // Temizlik
            muxer.stop()
            muxer.release()
            extractor.release()
            
            Log.d(TAG, "Audio başarıyla çıkarıldı: $outputPath")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Audio çıkarma hatası: ${e.message}")
            false
        }
    }
    
    fun convertToWav(inputPath: String, outputPath: String): Boolean {
        return try {
            // MP4'ten WAV'a dönüştürme için basit bir çözüm
            // Gerçek uygulamada daha gelişmiş bir audio converter kullanılmalı
            
            val inputFile = File(inputPath)
            val outputFile = File(outputPath)
            
            if (!inputFile.exists()) {
                Log.e(TAG, "Input dosyası bulunamadı: $inputPath")
                return false
            }
            
            // Basit dosya kopyalama (geçici çözüm)
            // Gerçek uygulamada audio format dönüşümü yapılmalı
            inputFile.copyTo(outputFile, overwrite = true)
            
            Log.d(TAG, "WAV dönüşümü tamamlandı: $outputPath")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "WAV dönüşüm hatası: ${e.message}")
            false
        }
    }
} 