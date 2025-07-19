import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Geri dönmek için

class LiveVideoCallPage extends StatelessWidget {
  final String volunteerName; // Hangi gönüllü ile görüşüldüğünü belirtmek için

  const LiveVideoCallPage({super.key, required this.volunteerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$volunteerName ile Canlı Görüşme', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6E21B5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Önceki sayfaya geri dön
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              '$volunteerName ile canlı video akışı buraya gelecek.',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Gerçek zamanlı video görüşmesi için WebRTC entegrasyonu gereklidir.',
              style: TextStyle(fontSize: 14, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Burada görüşmeyi sonlandırma veya başka bir aksiyon eklenebilir
                context.pop(); // Görüşmeyi sonlandırıp geri dön
              },
              icon: const Icon(Icons.call_end),
              label: const Text('Görüşmeyi Sonlandır'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Kırmızı buton
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
