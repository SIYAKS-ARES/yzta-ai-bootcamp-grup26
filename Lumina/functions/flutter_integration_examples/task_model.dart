// FRONTEND EKİBİ İÇİN - lib/models/task_model.dart
// Bu dosyayı Flutter projenizin lib/models/ klasörüne kopyalayın

import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String userId;
  final String fileName;
  final String status; // pending, processing, completed, failed
  final String? audioUrl;
  final String? audioPath;
  final String? errorMessage;
  final int? processedTextLength;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Task({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.status,
    this.audioUrl,
    this.audioPath,
    this.errorMessage,
    this.processedTextLength,
    required this.createdAt,
    this.updatedAt,
  });

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Task(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      fileName: data['fileName'] ?? '',
      status: data['status'] ?? 'pending',
      audioUrl: data['audioUrl'],
      audioPath: data['audioPath'],
      errorMessage: data['errorMessage'],
      processedTextLength: data['processedTextLength'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fileName': fileName,
      'status': status,
      'audioUrl': audioUrl,
      'audioPath': audioPath,
      'errorMessage': errorMessage,
      'processedTextLength': processedTextLength,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Görevin tamamlanıp tamamlanmadığını kontrol eder
  bool get isCompleted => status == 'completed';

  // Görevin işlenip işlenmediğini kontrol eder
  bool get isProcessing => status == 'processing';

  // Görevin başarısız olup olmadığını kontrol eder
  bool get isFailed => status == 'failed';

  // Görevin beklemede olup olmadığını kontrol eder
  bool get isPending => status == 'pending';

  @override
  String toString() {
    return 'Task(id: $id, fileName: $fileName, status: $status)';
  }
}
