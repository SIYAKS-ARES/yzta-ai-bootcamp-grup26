/*
// FRONTEND EKİBİ İÇİN - lib/screens/tts_upload_screen.dart
// Bu dosyayı Flutter projenizin lib/screens/ klasörüne kopyalayın

import 'dart:io';
import 'package:flutter/material.dart';
//import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
//import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import '../models/task_model.dart';
//import '../services/tts_service.dart';

class TTSUploadScreen extends StatefulWidget {
  const TTSUploadScreen({super.key});

  @override
  State<TTSUploadScreen> createState() => _TTSUploadScreenState();
}

//class _TTSUploadScreenState extends State<TTSUploadScreen> {
  //final TTSService _ttsService = TTSService();
  //final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeTaskId;
  bool _isUploading = false;
  String? _uploadProgress;

  @override
  void initState() {
    //super.initState();
    // Audio player durumunu dinle
    //_audioPlayer.playerStateStream.listen((state) {
    //  if (mounted) setState(() {});
    //});
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: false, // Performans için
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isUploading = true;
        _activeTaskId = null;
        _uploadProgress = 'Dosya hazırlanıyor...';
      });

      final file = File(result.files.single.path!);
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        //_showSnackBar('Lütfen önce giriş yapın.', isError: true);
        setState(() => _isUploading = false);
        return;
      }

      //try {
        setState(() => _uploadProgress = 'Dosya yükleniyor...');

        /*final taskId = await _ttsService.uploadFileAndCreateTask(
          file: file,
          userId: userId,
        );*/

        //setState(() {
          //_isUploading = false;
          //_uploadProgress = null;
          /*if (taskId != null) {
            _activeTaskId = taskId;
            _showSnackBar('Dosya başarıyla yüklendi! İşlem başlıyor...');
          } else {
            _showSnackBar('Dosya yüklenemedi.', isError: true);
          }
        });
      } catch (e) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
        });
        _showSnackBar('Hata: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _playAudio(String url) async {
    try {
      /*if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }*/
      //await _audioPlayer.setUrl(url);
      //await _audioPlayer.play();
    } catch (e) {
      _showSnackBar('Ses oynatılırken hata oluştu: $e', isError: true);
    }
  }

  Future<void> _pauseAudio() async {
    try {
      //await _audioPlayer.pause();
    } catch (e) {
      _showSnackBar('Ses duraklatılırken hata oluştu: $e', isError: true);
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text-to-Speech'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık ve açıklama
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doküman Seslendirme',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF veya DOCX dosyalarınızı yükleyin ve yapay zeka ile seslendirilmesini sağlayın.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dosya yükleme butonu
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _isUploading ? 'Yükleniyor...' : 'Dosya Seç ve Yükle',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            // Upload progress
            if (_uploadProgress != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Text(_uploadProgress!),
                    ],
                  ),
                ),
              ),
            ],

            // Görev durumu
            if (_activeTaskId != null) ...[
              const SizedBox(height: 16),
              StreamBuilder<Task>(
                stream: _ttsService.getTaskStream(_activeTaskId!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Hata: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Görev bilgisi yükleniyor...'),
                          ],
                        ),
                      ),
                    );
                  }

                  return _buildTaskStatusWidget(snapshot.data!);
                },
              ),
            ],

            const Spacer(),

            // Yardım metni
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Bilgi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Sadece PDF ve DOCX dosyaları desteklenir\n'
                      '• Maksimum dosya boyutu: 10MB\n'
                      '• İşlem süresi dosya boyutuna göre değişir\n'
                      '• Ses dosyası Türkçe olarak oluşturulur',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusWidget(Task task) {
    switch (task.status) {
      case 'pending':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Dosya: ${task.fileName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Dosya işleme sırasında bekliyor...'),
              ],
            ),
          ),
        );

      case 'processing':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Dosya: ${task.fileName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Dosya işleniyor ve sese dönüştürülüyor...'),
              ],
            ),
          ),
        );

      case 'completed':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tamamlandı: ${task.fileName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (task.processedTextLength != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'İşlenen metin uzunluğu: ${task.processedTextLength} karakter',
                  ),
                ],

                const SizedBox(height: 16),

                // Audio player controls
                StreamBuilder<Duration?>(
                  stream: _audioPlayer.durationStream,
                  builder: (context, durationSnapshot) {
                    return StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, positionSnapshot) {
                        final duration = durationSnapshot.data;
                        final position = positionSnapshot.data ?? Duration.zero;

                        return Column(
                          children: [
                            // Progress bar
                            if (duration != null) ...[
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                ),
                                child: Slider(
                                  value: position.inMilliseconds.toDouble(),
                                  max: duration.inMilliseconds.toDouble(),
                                  onChanged: (value) {
                                    _audioPlayer.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position)),
                                    Text(_formatDuration(duration)),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Play/Pause button
                            StreamBuilder<PlayerState>(
                              stream: _audioPlayer.playerStateStream,
                              builder: (context, playerStateSnapshot) {
                                final playerState = playerStateSnapshot.data;
                                final isPlaying = playerState?.playing ?? false;
                                final isLoading =
                                    playerState?.processingState ==
                                    ProcessingState.loading;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading)
                                      const CircularProgressIndicator()
                                    else
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (isPlaying) {
                                            _pauseAudio();
                                          } else {
                                            _playAudio(task.audioUrl!);
                                          }
                                        },
                                        icon: Icon(
                                          isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                        label: Text(
                                          isPlaying ? 'Duraklat' : 'Oynat',
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );

      case 'failed':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hata: ${task.fileName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.errorMessage ?? 'Bilinmeyen bir hata oluştu.',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _activeTaskId = null);
                  },
                  child: const Text('Yeni Dosya Yükle'),
                ),
              ],
            ),
          ),
        );

      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Bilinmeyen durum: ${task.status}'),
          ),
        );
    }
  }

  /*@override
  void dispose() {
    //_audioPlayer.dispose();
    super.dispose();
  }*/
}

}*/

}
*/
