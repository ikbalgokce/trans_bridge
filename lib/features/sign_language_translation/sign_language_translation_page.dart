import 'package:flutter/material.dart';

// Bu sayfa artık HomeView'a taşınan İşaret Dili Çevirisi işlevselliğinin
// eski yer tutucusudur. Şimdilik boş bir sayfa olarak bırakılmıştır.
// İleride tamamen kaldırılabilir veya farklı bir amaç için kullanılabilir.
class SignLanguageTranslationPage extends StatelessWidget {
  const SignLanguageTranslationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşaret Dili Çevirisi (Eski)', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red, // Farklı bir renk koydum ki eski sayfa olduğu anlaşılsın
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Bu sayfanın işlevselliği artık Ana Sayfa\'ya taşındı.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }
}