import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trans_bridge/app/router.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:trans_bridge/main.dart'; // Global 'cameras' değişkenine erişim için

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Mod kontrolü: true ise İşaret -> Konuşma, false ise Konuşma -> İşaret
  bool _isSignLanguageMode = true; 

  // İşaret -> Konuşma modu için kamera değişkenleri
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Timer? _timer;
  String _detectedText = ''; // Algılanan işaret dili metni
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Backend URL'i: Kendi Flask sunucunuzun IP adresini kullanmalısınız.
  // Eğer aynı bilgisayarda çalışıyorsa 127.00.1 (localhost) yeterlidir.
  // Ama mobil cihazda test ediyorsanız, bilgisayarınızın yerel ağ IP'si (örn. 192.168.1.111) olmalı.
  final String _backendUrl = 'http://192.168.1.111:5000/process_frame'; // Burayı KENDİ IP ADRESİNİZE göre güncelleyin!

  // Konuşma -> İşaret modu için değişkenler
  String _spokenText = ''; // Algılanan konuşma metni
  String _avatarSignText = 'Avatar burada işaret dilini gösterecek...'; // Avatarın göstereceği işaret dili metni
  bool _isListening = false; // Ses dinleme durumu (şimdilik simüle edilecek)
  Timer? _speechTimer; // Konuşma algılama simülasyonu için

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Kamera her zaman başlatılır
  }

  // Kamera başlatma ve akışını yönetme
  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _detectedText = 'Kamera bulunamadı veya başlatılamadı.';
        });
      }
      return;
    }

    _cameraController = CameraController(
      cameras[0], // İlk kamerayı kullan
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
      // Sadece işaret dili modundaysa akışı başlat
      if (_isSignLanguageMode) {
        _startImageStreaming();
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _detectedText = 'Kamera başlatılamadı: ${e.code}';
        });
      }
    }
  }

  // İşaret dili akışını başlatma
  void _startImageStreaming() {
    _timer?.cancel();
    if (_isSignLanguageMode) {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _sendFrameToBackend();
      });
    }
  }

  // Kareleri backend'e gönderme
  Future<void> _sendFrameToBackend() async {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'image': base64Image}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _detectedText = data['detected_text'] ?? 'Algılanan metin yok.';
        });
        if (data['audio_base64'] != null && _isSignLanguageMode) {
          _playAudio(data['audio_base64']);
        }
      } else {
        setState(() {
          _detectedText = 'API Hatası: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detectedText = 'Bağlantı hatası: ${e.toString()}';
      });
    }
  }

  // Sesi oynatma
  Future<void> _playAudio(String base64String) async {
    try {
      final Uint8List audioBytes = base64Decode(base64String);
      await _audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      print('Ses oynatma hatası: $e');
    }
  }

  // Konuşma -> İşaret modu için simülasyon
  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _spokenText = 'Dinleniyor...';
        _avatarSignText = 'Ses algılandığında avatar burada işaret dilini gösterecek.';
        _speechTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _spokenText = 'Merhaba, nasılsın?';
              _avatarSignText = 'Merhaba, nasılsın? (İşaret Dili)'; // Simüle edilmiş işaret dili
              _isListening = false;
            });
          }
        });
      } else {
        _speechTimer?.cancel();
        _spokenText = '';
        _avatarSignText = 'Avatar burada işaret dilini gösterecek...';
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechTimer?.cancel();
    _cameraController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6E21B5), // Mor arka plan
      // Ana Column'u SingleChildScrollView ile sarmalayarak taşmayı önlüyoruz
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Mod değiştirme switch'i
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sol taraftaki metin: Switch false (sol) iken aktif olan mod
                const Text(
                  'SES → İŞARET DİLİ', // Bu metin sola geldi
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                  child: Switch(
                    value: _isSignLanguageMode, // _isSignLanguageMode true ise İşaret->Konuşma
                    onChanged: (val) {
                      setState(() {
                        _isSignLanguageMode = val;
                        if (_isSignLanguageMode) { // İşaret -> Konuşma moduna geçiş
                          _startImageStreaming();
                          _spokenText = ''; // Diğer modun metinlerini temizle
                          _avatarSignText = 'Avatar burada işaret dilini gösterecek...';
                          _isListening = false;
                          _speechTimer?.cancel();
                        } else { // Konuşma -> İşaret moduna geçiş
                          _timer?.cancel(); // Kamera akışını durdur
                          _detectedText = ''; // Diğer modun metinlerini temizle
                          _audioPlayer.stop(); // Sesi durdur
                        }
                      });
                    },
                    activeColor: const Color(0xFF6E21B5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Sağ taraftaki metin: Switch true (sağ) iken aktif olan mod
                const Text(
                  'İŞARET DİLİ → SES', // Bu metin sağa geldi
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Ana içerik alanı (modlara göre değişecek)
            SizedBox(
              // Yüksekliği esnek hale getirmek için kaldırıldı veya daha küçük bir değer verildi
              // height: 480, // Bu satır kaldırıldı veya yorum satırı yapıldı
              child: Center(
                child: Container(
                  width: 365,
                  // height: 465, // Bu da kaldırıldı, içeriğe göre boyutlanacak
                  padding: const EdgeInsets.all(16.0), // İç padding eklendi
                  decoration: BoxDecoration(
                    color: const Color(0xFF232B36),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isSignLanguageMode // İşaret -> Konuşma modu
                      ? Column(
                          mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt, color: Colors.red),
                                SizedBox(width: 8),
                                Text('KAMERA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Kamera önizleme alanı
                            Container(
                              height: 250, 
                              width: double.infinity, // Genişliği tam yap
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black),
                              ),
                              child: _isCameraInitialized && _cameraController!.value.isInitialized
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: AspectRatio(
                                        aspectRatio: _cameraController!.value.aspectRatio,
                                        child: CameraPreview(_cameraController!),
                                      ),
                                    )
                                  : const Center(child: CircularProgressIndicator(color: Color(0xFF6E21B5))),
                            ),
                            const SizedBox(height: 20),
                            const Text('ALGILANAN METİN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(minHeight: 80, maxHeight: 120), // Metin kutusu yüksekliği
                              width: double.infinity, // Genişliği tam yap
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black),
                              ),
                              child: SingleChildScrollView(
                                child: Text(_detectedText, style: const TextStyle(fontSize: 16, color: Colors.black)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  iconSize: 40,
                                  color: Colors.black,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: () {
                                    // Ses oynatma mantığı _sendFrameToBackend içinde zaten var.
                                    // Eğer burada manuel oynatma isteniyorsa, _detectedText'in son sesini tekrar çalabiliriz.
                                    // Şimdilik pasif bırakalım, otomatik oynatma yeterli.
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.stop),
                                  iconSize: 40,
                                  color: Colors.black,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: () {
                                    _audioPlayer.stop(); // Sesi durdur
                                  },
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column( // Konuşma -> İşaret modu
                          mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
                          children: [
                            // Mikrofon butonu
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                size: 80,
                                color: _isListening ? Colors.red : Colors.white,
                              ),
                              onPressed: _toggleListening,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'KONUŞULAN METİN',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(minHeight: 80, maxHeight: 120), // Yükseklik ayarlandı
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black),
                              ),
                              child: SingleChildScrollView(
                                child: Text(_spokenText, style: const TextStyle(fontSize: 16, color: Colors.black)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'AVATAR İŞARET DİLİ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            // Avatar için daha büyük bir boşluk
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              height: 180, // Avatar için daha büyük yükseklik
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black),
                              ),
                              child: Center( // Metni ortalamak için
                                child: SingleChildScrollView(
                                  child: Text(
                                    _avatarSignText,
                                    textAlign: TextAlign.center, // Metni ortala
                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Chat Bot butonu (her iki modda da aynı kalacak)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6E21B5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: () {
                  context.go(AppRoutes.livesupport); // Canlı destek sayfasına git
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF6E21B5)),
                    SizedBox(width: 8),
                    Text(
                      'Chat Bot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6E21B5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
