import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// TODO: Replace placeholders with actual pages once features are implemented
// import 'package:news_app_clean_architecture/features/articles/presentation/pages/dashboard/articles_dashboard_page.dart';
// import 'package:news_app_clean_architecture/features/auth/presentation/pages/login/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // TODO: return const ArticlesDashboardPage();
          return const Scaffold(body: Center(child: Text('Dashboard')));
        }
        // TODO: return const LoginPage();
        return const Scaffold(body: Center(child: Text('Login')));
      },
    );
  }
}
