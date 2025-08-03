use anyhow::Result;
use flutter_rust_bridge::*;
use serde::{Deserialize, Serialize};
use std::path::Path;
use whisper_rs::{FullParams, SamplingStrategy, WhisperContext};

#[derive(Debug, Serialize, Deserialize)]
pub struct TranscriptSegment {
    pub start: f64,
    pub end: f64,
    pub text: String,
    pub confidence: f32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TranscriptResult {
    pub segments: Vec<TranscriptSegment>,
    pub full_text: String,
    pub language: String,
    pub duration: f64,
}

fn initialize_whisper_internal(model_path: &str) -> Result<bool> {
    if !Path::new(model_path).exists() {
        return Err(anyhow::anyhow!("Model dosyası bulunamadı: {}", model_path));
    }

    // Model dosyasının varlığını kontrol et
    let _context = WhisperContext::new_with_params(model_path, Default::default())?;
    Ok(true)
}

fn transcribe_audio_internal(model_path: &str, audio_path: &str) -> Result<TranscriptResult> {
    let context = WhisperContext::new_with_params(model_path, Default::default())?;

    // Audio dosyasını yükle
    let mut reader = hound::WavReader::open(audio_path)?;
    let samples: Vec<i16> = reader.samples().collect::<Result<Vec<i16>, _>>()?;
    
    // i16'dan f32'ye dönüştür
    let samples_f32: Vec<f32> = samples.iter().map(|&s| s as f32 / 32768.0).collect();
    
    // Whisper parametrelerini ayarla
    let mut params = FullParams::new(SamplingStrategy::Greedy { best_of: 1 });
    params.set_language(Some("tr")); // Türkçe için
    params.set_print_special(false);
    params.set_print_progress(false);
    params.set_print_timestamps(true);
    params.set_single_segment(false);

    // Transkript oluştur
    let mut state = context.create_state()?;
    state.full(params, &samples_f32)?;

    // Segmentleri al
    let num_segments = state.full_n_segments()?;
    let mut segments = Vec::new();
    let mut full_text = String::new();
    let mut total_duration = 0.0;

    for i in 0..num_segments {
        let segment = state.full_get_segment_text(i)?;
        let start = state.full_get_segment_t0(i)? as f64 / 100.0;
        let end = state.full_get_segment_t1(i)? as f64 / 100.0;
        
        segments.push(TranscriptSegment {
            start,
            end,
            text: segment.trim().to_string(),
            confidence: 0.9, // Whisper.cpp confidence değeri yok, varsayılan
        });
        
        full_text.push_str(&segment);
        full_text.push(' ');
        total_duration = end;
    }

    Ok(TranscriptResult {
        segments,
        full_text: full_text.trim().to_string(),
        language: "tr".to_string(),
        duration: total_duration,
    })
}

fn extract_audio_from_video(video_path: &str) -> Result<String> {
    use std::process::Command;
    
    let temp_dir = std::env::temp_dir();
    let audio_path = temp_dir.join("extracted_audio.wav");
    
    let output = Command::new("ffmpeg")
        .args(&[
            "-i", video_path,
            "-vn", // Video stream'i kaldır
            "-acodec", "pcm_s16le", // 16-bit PCM
            "-ar", "16000", // 16kHz sample rate
            "-ac", "1", // Mono
            "-y", // Overwrite
            audio_path.to_str().unwrap(),
        ])
        .output()?;

    if !output.status.success() {
        return Err(anyhow::anyhow!(
            "FFmpeg hatası: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(audio_path.to_string_lossy().to_string())
}

// Flutter Rust Bridge API
pub fn initialize_whisper(model_path: String) -> Result<bool> {
    initialize_whisper_internal(&model_path)
}

pub fn transcribe_video_with_whisper(
    model_path: String,
    video_path: String,
) -> Result<TranscriptResult> {
    // Video'dan audio çıkar (FFmpeg ile)
    let audio_path = extract_audio_from_video(&video_path)?;
    
    // Audio'yu transkript et
    let result = transcribe_audio_internal(&model_path, &audio_path)?;
    
    // Geçici audio dosyasını sil
    if let Err(e) = std::fs::remove_file(&audio_path) {
        eprintln!("Geçici audio dosyası silinemedi: {}", e);
    }
    
    Ok(result)
}

pub fn transcribe_audio_with_whisper(
    model_path: String,
    audio_path: String,
) -> Result<TranscriptResult> {
    transcribe_audio_internal(&model_path, &audio_path)
} 