import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trans_bridge/app/router.dart'; // AppRoutes'a erişmek için

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _acceptKvkk = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6E21B5), // Mor tema rengi
        foregroundColor: Colors.white, // Başlık rengi
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              'BRIDGE TRANS AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6E21B5),
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-posta veya Kullanıcı Adı',
                hintText: 'E-posta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _acceptKvkk,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _acceptKvkk = newValue ?? false;
                    });
                  },
                  activeColor: const Color(0xFF6E21B5),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _acceptKvkk = !_acceptKvkk;
                      });
                    },
                    child: const Text(
                      'KVKK Kanunu kapsamında kişisel verilerimin işlenmesini kabul ediyorum.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              // Bu butona basıldığında doğrudan ana sayfaya yönlendiriyoruz
              onPressed: () {
                // Normalde burada kimlik doğrulama mantığı olurdu.
                // Şimdilik doğrudan ana sayfaya yönlendiriyoruz.
                context.go(AppRoutes.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E21B5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Giriş Yap',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    context.go(AppRoutes.forgotPassword); // Şifremi Unuttum sayfasına git
                  },
                  child: const Text(
                    'Şifremi Unuttum?',
                    style: TextStyle(color: Color(0xFF6E21B5)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go(AppRoutes.register); // Kayıt Ol sayfasına git
                  },
                  child: const Text(
                    'Kayıt Ol',
                    style: TextStyle(color: Color(0xFF6E21B5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
