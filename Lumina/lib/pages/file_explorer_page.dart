import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({super.key});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  List<FileSystemEntity> files = [];
  List<FileSystemEntity> directories = [];
  Directory? currentDirectory;
  bool isLoading = false;
  String currentPath = '';

  @override
  void initState() {
    super.initState();
    _initializeFileExplorer();
  }

  Future<void> _initializeFileExplorer() async {
    setState(() {
      isLoading = true;
    });

    try {
      // İzinleri kontrol et
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        // Başlangıç dizinini al
        Directory? startDir;

        // Platform kontrolü
        if (Platform.isAndroid) {
          // Android için Downloads klasörü
          startDir = Directory('/storage/emulated/0/Download');
          if (!await startDir.exists()) {
            startDir = Directory('/storage/emulated/0/Downloads');
          }
          if (!await startDir.exists()) {
            startDir = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          // iOS için Documents klasörü
          startDir = await getApplicationDocumentsDirectory();
        } else {
          // Web/Desktop için test klasörü
          startDir = await getApplicationDocumentsDirectory();
        }

        if (startDir != null && await startDir.exists()) {
          currentDirectory = startDir;
          currentPath = startDir.path;
          await _loadDirectoryContents(startDir);
        } else {
          // Fallback: Ana dizin
          currentDirectory = Directory('/');
          currentPath = '/';
          await _loadDirectoryContents(Directory('/'));
        }
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      debugPrint('Dosya yöneticisi başlatılırken hata: $e');
      // Hata durumunda test verileri göster
      _loadTestData();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDirectoryContents(Directory dir) async {
    try {
      List<FileSystemEntity> entities = await dir.list().toList();

      List<FileSystemEntity> dirs = [];
      List<FileSystemEntity> files = [];

      for (var entity in entities) {
        try {
          if (await entity.exists()) {
            if (entity is Directory) {
              dirs.add(entity);
            } else if (entity is File) {
              // Sadece PDF ve ses dosyalarını göster
              String extension = entity.path.split('.').last.toLowerCase();
              if (['pdf', 'mp3', 'wav', 'm4a', 'txt'].contains(extension)) {
                files.add(entity);
              }
            }
          }
        } catch (e) {
          // Dosyaya erişim hatası, atla
          continue;
        }
      }

      setState(() {
        directories = dirs;
        this.files = files;
      });
    } catch (e) {
      debugPrint('Dizin içeriği yüklenirken hata: $e');
    }
  }

  void _loadTestData() {
    // PC'de test için örnek veriler
    setState(() {
      directories = [
        Directory('C:/Users/Test/Documents'),
        Directory('C:/Users/Test/Downloads'),
        Directory('C:/Users/Test/Desktop'),
      ];
      files = [
        File('C:/Users/Test/Documents/test.pdf'),
        File('C:/Users/Test/Downloads/sample.mp3'),
        File('C:/Users/Test/Desktop/document.pdf'),
      ];
      currentPath = 'C:/Users/Test';
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İzin Gerekli'),
        content: Text('Dosyalara erişim için depolama izni gereklidir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeFileExplorer();
            },
            child: Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDirectory(Directory dir) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _loadDirectoryContents(dir);
      currentDirectory = dir;
      currentPath = dir.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dizine erişilemiyor: $e')));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _navigateBack() async {
    if (currentDirectory != null) {
      Directory? parent = currentDirectory!.parent;
      if (await parent.exists()) {
        await _navigateToDirectory(parent);
      }
    }
  }

  Future<void> _processFile(File file) async {
    String extension = file.path.split('.').last.toLowerCase();

    if (extension == 'pdf') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF dosyası seçildi: ${file.path.split('/').last}'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (['mp3', 'wav', 'm4a'].contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ses dosyası seçildi: ${file.path.split('/').last}'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bu dosya türü desteklenmiyor')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dosya Yöneticisi'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeFileExplorer,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mevcut yol
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Icon(Icons.folder, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentPath,
                          style: TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Geri butonu
                if (currentDirectory != null)
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: _navigateBack,
                        ),
                        Text('Geri'),
                      ],
                    ),
                  ),

                // İçerik listesi
                Expanded(
                  child: ListView(
                    children: [
                      // Dizinler
                      if (directories.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Klasörler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        ...directories.map(
                          (dir) => ListTile(
                            leading: Icon(Icons.folder, color: Colors.orange),
                            title: Text(dir.path.split('/').last),
                            subtitle: Text('Klasör'),
                            onTap: () => _navigateToDirectory(dir as Directory),
                          ),
                        ),
                      ],

                      // Dosyalar
                      if (files.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Dosyalar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        ...files.map((file) {
                          String extension = file.path
                              .split('.')
                              .last
                              .toLowerCase();
                          IconData iconData;
                          Color iconColor;

                          switch (extension) {
                            case 'pdf':
                              iconData = Icons.picture_as_pdf;
                              iconColor = Colors.red;
                              break;
                            case 'mp3':
                            case 'wav':
                            case 'm4a':
                              iconData = Icons.audiotrack;
                              iconColor = Colors.green;
                              break;
                            default:
                              iconData = Icons.insert_drive_file;
                              iconColor = Colors.grey;
                          }

                          return ListTile(
                            leading: Icon(iconData, color: iconColor),
                            title: Text(file.path.split('/').last),
                            subtitle: Text(
                              '${extension.toUpperCase()} dosyası',
                            ),
                            trailing:
                                extension == 'pdf' ||
                                    ['mp3', 'wav', 'm4a'].contains(extension)
                                ? IconButton(
                                    icon: Icon(
                                      Icons.play_arrow,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    onPressed: () => _processFile(file as File),
                                  )
                                : null,
                            onTap: () => _processFile(file as File),
                          );
                        }),
                      ],

                      // Boş durum
                      if (directories.isEmpty && files.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Bu klasörde dosya bulunamadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
