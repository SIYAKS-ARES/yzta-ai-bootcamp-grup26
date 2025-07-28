import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkTheme = false;
  String selectedLanguage = "Türkçe";
  final List<String> languages = ["Türkçe", "English", "Deutsch"];

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Kullanıcı info header
          Card(
            elevation: 0,
            color: const Color(0xFFF1F5FB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF60A5FA),
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              title: const Text(
                "Ahmet Yılmaz",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: const Text("ahmet@mail.com"),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  // Profil düzenleme fonksiyonu
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Profil Düzenle"),
                      content: const Text("Bu özellik yakında eklenecek."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Tamam"),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dil seçimi
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Uygulama Dili"),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              items: languages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  if (val != null) selectedLanguage = val;
                });
              },
            ),
          ),
          const Divider(),

          // Bildirimler
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() {
                notificationsEnabled = val;
              });
            },
            secondary: const Icon(Icons.notifications),
            title: const Text("Bildirimleri Aç"),
          ),
          const Divider(),

          // Parola Değiştir
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text("Parola Değiştir"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Parola Değiştir"),
                  content: const Text("Bu özellik yakında aktif olacak."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    )
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Tema Değiştir
          SwitchListTile(
            value: darkTheme,
            onChanged: (val) {
              setState(() {
                darkTheme = val;
              });
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Tema"),
                  content: Text(val ? "Koyu tema seçildi." : "Açık tema seçildi."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    )
                  ],
                ),
              );
            },
            secondary: const Icon(Icons.brightness_6),
            title: const Text("Koyu Tema"),
          ),
          const Divider(),

          // Yardım ve Destek
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Yardım ve Destek"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Yardım & Destek"),
                  content: const Text("Her türlü soru için: destek@lumina.com"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    )
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Gizlilik Politikası
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Gizlilik Politikası"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Gizlilik Politikası"),
                  content: const Text("Gizlilik politikamız yakında yayınlanacaktır."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    )
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Güncellemeleri kontrol et
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text("Güncellemeleri Kontrol Et"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Güncellemeler"),
                  content: const Text("Uygulamanız güncel!"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),

          // Çıkış yap
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Çıkış Yap",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}