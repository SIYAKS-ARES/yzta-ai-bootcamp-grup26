import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class WebFileService {
  static final WebFileService _instance = WebFileService._internal();
  factory WebFileService() => _instance;
  WebFileService._internal();

  // Web platformu için dosya işleme
  Future<String> processFile(Uint8List bytes, String fileName) async {
    try {
      print(
        "Web dosya işleme başladı: $fileName, Boyut: ${bytes.length} bytes",
      );

      // Dosya türünü belirle
      final String fileType = _determineFileType(fileName);
      print("Belirlenen dosya türü: $fileType");

      switch (fileType) {
        case 'txt':
          return _processTextFile(bytes);
        case 'pdf':
          return _processPdfFile(bytes);
        default:
          throw Exception('Desteklenmeyen dosya türü: $fileType');
      }
    } catch (e) {
      print("Web dosya işleme hatası: $e");
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
      print("Dosya türü belirlenemedi, TXT olarak işleniyor: $fileName");
      return 'txt';
    }
  }

  // TXT dosyası işle
  String _processTextFile(Uint8List bytes) {
    try {
      print("TXT dosyası işleniyor...");
      final String text = String.fromCharCodes(bytes);
      print("TXT içeriği uzunluğu: ${text.length}");
      print(
        "TXT içeriği önizleme: ${text.substring(0, text.length > 50 ? 50 : text.length)}...",
      );
      return text;
    } catch (e) {
      print("TXT işleme hatası: $e");
      throw Exception('TXT dosyası işlenemedi: $e');
    }
  }

  // PDF dosyası işle
  String _processPdfFile(Uint8List bytes) {
    try {
      print("PDF dosyası işleniyor...");
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();

      print("PDF içeriği uzunluğu: ${text.length}");
      print(
        "PDF içeriği önizleme: ${text.substring(0, text.length > 50 ? 50 : text.length)}...",
      );
      return text.trim();
    } catch (e) {
      print("PDF işleme hatası: $e");
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
