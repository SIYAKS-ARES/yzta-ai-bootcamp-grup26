import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

enum StudentType { none, blind, deaf }

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StudentType selectedType = StudentType.none;

  // Video seçimi ve dialog gösterme
  Future<void> _pickAndTranscribeVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      String? filePath = result.files.single.path;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Video Seçildi!"),
          content: Text("Dosya adı: ${result.files.single.name}\n\n"
              "Dosya yolu:\n$filePath"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tamam"),
            ),
          ],
        ),
      );
      // Burada seçilen video backend'e gönderilip transkript alınabilir.
    } else {
      // Kullanıcı iptal etti, bir şey yapmaya gerek yok.
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);
    final Color cardBG = Colors.white;
    final Color borderBlue = const Color(0xFFE0E7FF);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, softBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hoş geldiniz ve ayarlar kutusu
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cardBG,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Hoş geldiniz, ${widget.userName}!",
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: primaryBlue),
                    tooltip: 'Ayarlar',
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Seçim kutusu
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBG,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Nasıl yardımcı olabilirim?",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SelectButton(
                          selected: selectedType == StudentType.blind,
                          icon: "👁️",
                          text: "Ben görme engelli bir öğrenciyim",
                          onTap: () {
                            setState(() {
                              selectedType = StudentType.blind;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectButton(
                          selected: selectedType == StudentType.deaf,
                          icon: "🦻",
                          text: "Ben işitme engelli bir öğrenciyim",
                          onTap: () {
                            setState(() {
                              selectedType = StudentType.deaf;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Sadece seçim yapılınca kartları göster
            if (selectedType == StudentType.blind)
              FeatureCard(
                icon: "📄",
                title: "PDF'ten Sese Dönüştür",
                description: "PDF dosyalarınızı sesli hale getirin.\nDinlemeye hemen başlayın.",
                buttonText: "+ PDF Yükle",
                onPressed: () {},
              ),

            if (selectedType == StudentType.deaf) ...[
              FeatureCard(
                icon: "🎧",
                title: "Sesten Metne Dönüştür",
                description: "Video veya ses dosyalarınızı metne çevirin.",
                buttonText: "+ Dosya Yükle",
                onPressed: () {},
              ),
              SizedBox(height: 12),
              FeatureCard(
                icon: "🎬",
                title: "Video Transkripti Oluştur",
                description: "Videolarınızı yükleyin, otomatik transkript oluşturulsun.",
                buttonText: "Video Ekle",
                onPressed: _pickAndTranscribeVideo,
              ),
            ],

            const SizedBox(height: 22),
            // Son Yüklenenler başlığı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBG,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderBlue),
              ),
              child: Text(
                "📂 Son Yüklenen Dosyalarım",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            // Son yüklenen dosya listesi burada olabilir
          ],
        ),
      ),
    );
  }
}

// Seçim butonu
class SelectButton extends StatelessWidget {
  final bool selected;
  final String icon;
  final String text;
  final VoidCallback onTap;

  const SelectButton({
    required this.selected,
    required this.icon,
    required this.text,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color active = const Color(0xFF2563EB);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? active : const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? active : const Color(0xFFDBEAFE),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 23)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.blueGrey[800],
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Özellik kartı
class FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onPressed;

  const FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color active = const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: active.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: active,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.blueGrey[700],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: active,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 42),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          )
        ],
      ),
    );
  }
}
