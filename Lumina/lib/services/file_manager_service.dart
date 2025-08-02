import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class FileManagerService {
  static final FileManagerService _instance = FileManagerService._internal();
  factory FileManagerService() => _instance;
  FileManagerService._internal();

  Directory? _appDocumentsDir;
  Directory? _filesDir;

  // Uygulama dosya dizinini başlat
  Future<void> initialize() async {
    if (_appDocumentsDir != null) return;

    try {
      _appDocumentsDir = await getApplicationDocumentsDirectory();
      _filesDir = Directory(
        path.join(_appDocumentsDir!.path, 'uploaded_files'),
      );

      // Dizin yoksa oluştur
      if (!await _filesDir!.exists()) {
        await _filesDir!.create(recursive: true);
      }

      // Dosya yöneticisi başlatıldı
    } catch (e) {
      // Dosya yöneticisi başlatma hatası
    }
  }

  // Dosyayı uygulama dizinine kopyala
  Future<String> copyFileToAppDirectory(
    String sourcePath,
    String fileName,
  ) async {
    await initialize();

    try {
      final File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Kaynak dosya bulunamadı: $sourcePath');
      }

      // Benzersiz dosya adı oluştur
      final String uniqueFileName = _generateUniqueFileName(fileName);
      final String destinationPath = path.join(_filesDir!.path, uniqueFileName);

      // Dosyayı kopyala - web platformu için farklı yaklaşım
      try {
        await sourceFile.copy(destinationPath);
      } catch (e) {
        // Web platformunda dosya kopyalama çalışmazsa, içeriği okuyup yeni dosya oluştur
        if (e.toString().contains('_Namespace') ||
            e.toString().contains('Unsupported operation')) {
          // Web platformu tespit edildi, alternatif yöntem kullanılıyor
          final Uint8List bytes = await sourceFile.readAsBytes();
          final File newFile = File(destinationPath);
          await newFile.writeAsBytes(bytes);
        } else {
          rethrow;
        }
      }

      // Dosya kopyalandı
      return destinationPath;
    } catch (e) {
      // Dosya kopyalama hatası
      throw Exception('Dosya kopyalanamadı: $e');
    }
  }

  // Benzersiz dosya adı oluştur
  String _generateUniqueFileName(String originalName) {
    final String extension = path.extension(originalName);
    final String nameWithoutExtension = path.basenameWithoutExtension(
      originalName,
    );
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '${nameWithoutExtension}_$timestamp$extension';
  }

  // Uygulama dizinindeki dosyaları listele
  Future<List<FileSystemEntity>> getUploadedFiles() async {
    await initialize();

    try {
      if (await _filesDir!.exists()) {
        return await _filesDir!.list().toList();
      }
      return [];
    } catch (e) {
      // Dosya listesi alma hatası
      return [];
    }
  }

  // Dosyayı oku
  Future<String> readFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Dosya bulunamadı: $filePath');
      }

      final String content = await file.readAsString();
      return content;
    } catch (e) {
      // Dosya okuma hatası
      throw Exception('Dosya okunamadı: $e');
    }
  }

  // Dosyayı sil
  Future<void> deleteFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        // Dosya silindi
      }
    } catch (e) {
      // Dosya silme hatası
    }
  }

  // Dosya boyutunu al
  Future<int> getFileSize(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      // Dosya boyutu alma hatası
      return 0;
    }
  }

  // Dosya türünü kontrol et
  bool isSupportedFileType(String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    return extension == '.pdf' || extension == '.txt';
  }

  // Dosya adını temizle
  String sanitizeFileName(String fileName) {
    // Özel karakterleri kaldır
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
