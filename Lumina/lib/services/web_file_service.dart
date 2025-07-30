import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:developer' as developer;

class WebFileService {
  static final WebFileService _instance = WebFileService._internal();
  factory WebFileService() => _instance;
  WebFileService._internal();

  // Web platformu için dosya işleme
  Future<String> processFile(Uint8List bytes, String fileName) async {
    try {
      developer.log(
        "Web dosya işleme başladı: $fileName, Boyut:  [${bytes.length} bytes",
        name: 'WebFileService',
      );

      // Dosya türünü belirle
      final String fileType = _determineFileType(fileName);
      developer.log("Belirlenen dosya türü: $fileType", name: 'WebFileService');

      switch (fileType) {
        case 'txt':
          return _processTextFile(bytes);
        case 'pdf':
          return _processPdfFile(bytes);
        default:
          throw Exception('Desteklenmeyen dosya türü: $fileType');
      }
    } catch (e) {
      developer.log("Web dosya işleme hatası: $e", name: 'WebFileService');
      throw Exception('Dosya işlenemedi: $e');
    }
  }

  // Dosya türünü belirle
  String _determineFileType(String fileName) {
    final String lowerFileName = fileName.toLowerCase();

    if (lowerFileName.endsWith('.txt') || lowerFileName.contains('.txt')) {
      return 'txt';
    } else if (lowerFileName.endsWith('.pdf') ||
        lowerFileName.contains('.pdf')) {
      return 'pdf';
    } else {
      // Varsayılan olarak TXT kabul et
      developer.log(
        "Dosya türü belirlenemedi, TXT olarak işleniyor: $fileName",
        name: 'WebFileService',
      );
      return 'txt';
    }
  }

  // TXT dosyası işle
  String _processTextFile(Uint8List bytes) {
    try {
      developer.log("TXT dosyası işleniyor...", name: 'WebFileService');
      final String text = String.fromCharCodes(bytes);
      developer.log(
        "TXT içeriği uzunluğu:  [${text.length}",
        name: 'WebFileService',
      );
      developer.log(
        "TXT içeriği önizleme:  [${text.substring(0, text.length > 50 ? 50 : text.length)}...",
        name: 'WebFileService',
      );
      return text;
    } catch (e) {
      developer.log("TXT işleme hatası: $e", name: 'WebFileService');
      throw Exception('TXT dosyası işlenemedi: $e');
    }
  }

  // PDF dosyası işle
  String _processPdfFile(Uint8List bytes) {
    try {
      developer.log("PDF dosyası işleniyor...", name: 'WebFileService');
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();

      developer.log(
        "PDF içeriği uzunluğu:  [${text.length}",
        name: 'WebFileService',
      );
      developer.log(
        "PDF içeriği önizleme:  [${text.substring(0, text.length > 50 ? 50 : text.length)}...",
        name: 'WebFileService',
      );
      return text.trim();
    } catch (e) {
      developer.log("PDF işleme hatası: $e", name: 'WebFileService');
      throw Exception('PDF dosyası işlenemedi: $e');
    }
  }

  // Dosya boyutunu formatla
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
