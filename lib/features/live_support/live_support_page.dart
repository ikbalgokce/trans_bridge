import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Rota yönetimi için
import 'package:trans_bridge/app/router.dart'; // AppRoutes için

class LiveSupportPage extends StatelessWidget {
  const LiveSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Destek', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6E21B5), // Mor tema rengi
        foregroundColor: Colors.white, // Başlık rengi
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Görüşmek istediğiniz gönüllü çevirmeni seçin:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Gönüllü çevirmen butonları
              _buildVolunteerButton(context, 'Ayşe'),
              const SizedBox(height: 15),
              _buildVolunteerButton(context, 'Can'),
              const SizedBox(height: 15),
              _buildVolunteerButton(context, 'Elif'),
            ],
          ),
        ),
      ),
    );
  }

  // Gönüllü butonu oluşturma yardımcı fonksiyonu
  Widget _buildVolunteerButton(BuildContext context, String name) {
    return SizedBox(
      width: 250, // Buton genişliği
      child: ElevatedButton(
        onPressed: () {
          // Gönüllü seçildiğinde canlı video görüşme sayfasına git
          context.go('${AppRoutes.livesupport}/${AppRoutes.liveVideoCall}/$name');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6E21B5), // Mor buton rengi
          foregroundColor: Colors.white, // Yazı rengi
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Yuvarlak köşeler
          ),
          elevation: 5, // Gölge efekti
        ),
        child: Text(
          '$name ile Görüş',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
