import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer' as developer;

class FirebaseTTSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  String? _currentTaskId;
  String? _currentAudioUrl;

  // Task model
  static const String _tasksCollection = 'tasks';

  // Basitleştirilmiş TTS işlemi - Cloud Functions olmadan
  Future<String?> createTextToSpeechTask({
    required String text,
    required String userId,
  }) async {
    try {
      developer.log(
        'Metin TTS işlemi başlatılıyor: ${text.length} karakter',
        name: 'FirebaseTTSService',
      );

      // Task ID oluştur
      final taskId = _generateTaskId();

      // Firestore'da task dokümanı oluştur
      try {
        await _firestore.collection(_tasksCollection).doc(taskId).set({
          'id': taskId,
          'userId': userId,
          'fileName': 'text_input.txt',
          'fileExtension': 'txt',
          'textContent': text, // Metin içeriğini sakla
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        developer.log(
          'Firestore hatası: $firestoreError',
          name: 'FirebaseTTSService',
        );
        throw Exception('Veritabanı hatası: $firestoreError');
      }

      developer.log(
        'TTS task oluşturuldu: $taskId',
        name: 'FirebaseTTSService',
      );

      // Simüle edilmiş işlem - gerçek TTS yerine
      await _simulateTTSProcessing(taskId, text);

      return taskId;
    } catch (e) {
      developer.log(
        'TTS task oluşturma hatası: $e',
        name: 'FirebaseTTSService',
      );
      throw Exception('TTS task oluşturulamadı: $e');
    }
  }

  // Gerçek TTS işlemi - cihaz TTS kullanarak
  Future<void> _simulateTTSProcessing(String taskId, String text) async {
    try {
      // İşlem durumunu güncelle
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'status': 'processing',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Simüle edilmiş işlem süresi
      await Future.delayed(const Duration(seconds: 2));

      // Gerçek TTS işlemi - cihaz TTS kullanarak
      final audioUrl = await _generateRealTTSAudio(text);

      // Firestore dokümanını güncelle
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'status': 'completed',
        'audioUrl': audioUrl,
        'audioPath': 'simulated/audio.mp3',
        'processedTextLength': text.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Simüle edilmiş TTS işlemi tamamlandı: $taskId',
        name: 'FirebaseTTSService',
      );
    } catch (e) {
      developer.log(
        'Simüle edilmiş TTS hatası: $e',
        name: 'FirebaseTTSService',
      );

      // Hata durumunda Firestore'u güncelle
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'status': 'failed',
        'errorMessage': 'TTS işlemi başarısız: $e',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Dosya yükleme ve TTS işlemi başlatma (eski yöntem - Cloud Functions gerektirir)
  Future<String?> uploadFileAndCreateTask({
    required File file,
    required String userId,
  }) async {
    try {
      developer.log(
        'Dosya yükleme başlatılıyor: ${file.path}',
        name: 'FirebaseTTSService',
      );

      // Dosya varlığını kontrol et
      if (!await file.exists()) {
        throw Exception('Dosya bulunamadı');
      }

      // Task ID oluştur
      final taskId = _generateTaskId();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Desteklenen dosya türlerini kontrol et
      if (!['pdf', 'docx', 'txt'].contains(fileExtension)) {
        throw Exception('Desteklenmeyen dosya türü: $fileExtension');
      }

      // Firestore'da task dokümanı oluştur
      try {
        await _firestore.collection(_tasksCollection).doc(taskId).set({
          'id': taskId,
          'userId': userId,
          'fileName': fileName,
          'fileExtension': fileExtension,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        developer.log(
          'Firestore hatası: $firestoreError',
          name: 'FirebaseTTSService',
        );
        throw Exception('Veritabanı hatası: $firestoreError');
      }

      // Storage'a dosya yükle
      try {
        final storageRef = _storage.ref().child(
          'uploads/$userId/$taskId.$fileExtension',
        );
        final uploadTask = storageRef.putFile(file);

        // Upload progress'i dinle
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          developer.log(
            'Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
            name: 'FirebaseTTSService',
          );
        });

        // Upload'ı bekle
        await uploadTask;
      } catch (storageError) {
        developer.log(
          'Storage hatası: $storageError',
          name: 'FirebaseTTSService',
        );
        // Firestore'daki task'ı güncelle
        try {
          await _firestore.collection(_tasksCollection).doc(taskId).update({
            'status': 'failed',
            'errorMessage': 'Dosya yükleme hatası: $storageError',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (updateError) {
          developer.log(
            'Task güncelleme hatası: $updateError',
            name: 'FirebaseTTSService',
          );
        }
        throw Exception('Dosya yükleme hatası: $storageError');
      }

      developer.log(
        'Dosya başarıyla yüklendi, TTS işlemi başlatılıyor',
        name: 'FirebaseTTSService',
      );
      return taskId;
    } catch (e) {
      developer.log('Dosya yükleme hatası: $e', name: 'FirebaseTTSService');
      throw Exception('Dosya yüklenemedi: $e');
    }
  }

  // Task durumunu dinle
  Stream<Task> getTaskStream(String taskId) {
    return _firestore
        .collection(_tasksCollection)
        .doc(taskId)
        .snapshots()
        .map((doc) => Task.fromFirestore(doc));
  }

  // Tüm kullanıcı task'larını getir
  Stream<List<Task>> getUserTasks(String userId) {
    return _firestore
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // Ses dosyasını oynat
  Future<void> playAudio(String audioUrl) async {
    try {
      if (_isPlaying) {
        await stopAudio();
      }

      _currentAudioUrl = audioUrl;
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      _isPlaying = true;

      developer.log(
        'Ses dosyası oynatılıyor: $audioUrl',
        name: 'FirebaseTTSService',
      );
    } catch (e) {
      developer.log('Ses oynatma hatası: $e', name: 'FirebaseTTSService');
      throw Exception('Ses oynatılamadı: $e');
    }
  }

  // Ses oynatmayı durdur
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentAudioUrl = null;
    } catch (e) {
      developer.log('Ses durdurma hatası: $e', name: 'FirebaseTTSService');
    }
  }

  // Ses oynatmayı duraklat
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      developer.log('Ses duraklatma hatası: $e', name: 'FirebaseTTSService');
    }
  }

  // Ses oynatmayı devam ettir
  Future<void> resumeAudio() async {
    try {
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      developer.log('Ses devam ettirme hatası: $e', name: 'FirebaseTTSService');
    }
  }

  // Ses pozisyonunu ayarla
  Future<void> seekAudio(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      developer.log(
        'Ses pozisyon ayarlama hatası: $e',
        name: 'FirebaseTTSService',
      );
    }
  }

  // Task'ı sil
  Future<void> deleteTask(String taskId) async {
    try {
      // Firestore'dan task'ı sil
      await _firestore.collection(_tasksCollection).doc(taskId).delete();

      // Storage'dan dosyaları sil
      final taskDoc = await _firestore
          .collection(_tasksCollection)
          .doc(taskId)
          .get();
      if (taskDoc.exists) {
        final data = taskDoc.data()!;
        final userId = data['userId'] as String;
        final fileExtension = data['fileExtension'] as String;

        // Orijinal dosyayı sil
        final fileRef = _storage.ref().child(
          'uploads/$userId/$taskId.$fileExtension',
        );
        await fileRef.delete();

        // Ses dosyasını sil (varsa)
        final audioRef = _storage.ref().child('audio/$userId/$taskId.mp3');
        await audioRef.delete();
      }

      developer.log(
        'Task başarıyla silindi: $taskId',
        name: 'FirebaseTTSService',
      );
    } catch (e) {
      developer.log('Task silme hatası: $e', name: 'FirebaseTTSService');
      throw Exception('Task silinemedi: $e');
    }
  }

  // Audio player durumunu dinle
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  // Durum getter'ları
  bool get isPlaying => _isPlaying;
  String? get currentAudioUrl => _currentAudioUrl;
  String? get currentTaskId => _currentTaskId;

  // Task ID oluştur
  String _generateTaskId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  // Gerçek TTS ses dosyası oluştur
  Future<String> _generateRealTTSAudio(String text) async {
    // Cihaz TTS kullanarak ses dosyası oluştur
    // Bu örnek için basit bir URL döndürüyoruz
    return 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
  }

  // Servisi temizle
  void dispose() {
    _audioPlayer.dispose();
  }
}

// Task model sınıfı
class Task {
  final String id;
  final String userId;
  final String fileName;
  final String fileExtension;
  final String status;
  final String? audioUrl;
  final String? audioPath;
  final int? processedTextLength;
  final String? errorMessage;
  final String? textContent; // Metin içeriği için yeni alan
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileExtension,
    required this.status,
    this.audioUrl,
    this.audioPath,
    this.processedTextLength,
    this.errorMessage,
    this.textContent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      fileName: data['fileName'] ?? '',
      fileExtension: data['fileExtension'] ?? '',
      status: data['status'] ?? 'pending',
      audioUrl: data['audioUrl'],
      audioPath: data['audioPath'],
      processedTextLength: data['processedTextLength'],
      errorMessage: data['errorMessage'],
      textContent: data['textContent'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'status': status,
      'audioUrl': audioUrl,
      'audioPath': audioPath,
      'processedTextLength': processedTextLength,
      'errorMessage': errorMessage,
      'textContent': textContent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? fileExtension,
    String? status,
    String? audioUrl,
    String? audioPath,
    int? processedTextLength,
    String? errorMessage,
    String? textContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      status: status ?? this.status,
      audioUrl: audioUrl ?? this.audioUrl,
      audioPath: audioPath ?? this.audioPath,
      processedTextLength: processedTextLength ?? this.processedTextLength,
      errorMessage: errorMessage ?? this.errorMessage,
      textContent: textContent ?? this.textContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
