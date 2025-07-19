import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:trans_bridge/views/app_view.dart';
import 'package:trans_bridge/views/home_view/home_view.dart'; // Ana sayfa
import 'package:trans_bridge/views/past_view/past_view.dart';
import 'package:trans_bridge/views/profile_view/profile_view.dart';
import 'package:trans_bridge/features/live_support/live_support_page.dart'; // Canlı destek listesi
import 'package:trans_bridge/features/live_support/live_video_call_page.dart'; // Canlı video görüşmesi
import 'package:trans_bridge/views/login_view.dart'; // Login sayfası
import 'package:trans_bridge/views/register_view.dart'; // Register sayfası
import 'package:trans_bridge/views/forgot_password_view.dart'; // Forgot Password sayfası
import 'package:trans_bridge/features/sign_language_translation/sign_language_translation_page.dart'; // Basitleştirilmiş sayfa için (isteğe bağlı)


final _routerKey = GlobalKey<NavigatorState>();

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String past = '/past';
  static const String livesupport = '/livesupport';
  static const String profile = '/profile';
  static const String liveVideoCall = 'call'; // livesupport altında nested rota

  // Login/Register/Forgot Password rotaları
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // İşaret Dili Çevirisi artık HomeView içinde olduğu için bu rotaya gerek kalmadı.
  // Ancak, eğer basitleştirilmiş SignLanguageTranslationPage'e erişmek istersen tutabiliriz.
  // Şimdilik kaldırıyorum, çünkü ana işlevsellik HomeView'da.
  // static const String signLanguage = '/sign_language'; 
}

final router = GoRouter(
  navigatorKey: _routerKey,
  initialLocation: AppRoutes.login, // Uygulamanın başlangıç rotası hala login
  routes: [
    // Login, Register, Forgot Password rotaları
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordView(),
    ),
    
    // Uygulamanın ana navigasyon yapısı (alt gezinme çubuğu olan sayfalar)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppView(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeView(), // HomeView artık işaret dili çevirisini içeriyor
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.past,
              builder: (context, state) => const PastView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.livesupport,
              builder: (context, state) => const LiveSupportPage(), // Canlı destek listesi sayfası
              routes: [
                GoRoute(
                  path: AppRoutes.liveVideoCall + '/:volunteerName', // /livesupport/call/:volunteerName
                  builder: (BuildContext context, GoRouterState state) {
                    final volunteerName = state.pathParameters['volunteerName']!;
                    return LiveVideoCallPage(volunteerName: volunteerName);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
      ],
    ),
    // Eğer basitleştirilmiş SignLanguageTranslationPage'i hala bir rota olarak tutmak istersen
    // GoRoute(
    //   path: AppRoutes.signLanguage,
    //   builder: (BuildContext context, GoRouterState state) {
    //     return const SignLanguageTranslationPage();
    //   },
    // ),
  ],
);

