import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/Provider/auth_provider.dart' as app_auth;
import 'package:recipe_app/Provider/favorite_provider.dart';
import 'package:recipe_app/Provider/quantity.dart';
import 'package:recipe_app/Provider/theme_provider.dart';
import 'package:recipe_app/Provider/collections_provider.dart';
import 'package:recipe_app/Provider/notification_provider.dart';
import 'package:recipe_app/Views/app_main_screen.dart';
import 'package:recipe_app/Views/login_screen.dart';
import 'package:recipe_app/Views/admin_screens.dart';
import 'package:recipe_app/Utils/migration_helper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Khởi tạo ThemeProvider
  final themeProvider = ThemeProvider();
  await themeProvider.initializeTheme();
  
  // Chạy migration cho các công thức hiện có
  try {
    final needsMigration = await MigrationHelper.needsMigration();
    if (needsMigration) {
      await MigrationHelper.migrateExistingRecipes();
    }
  } catch (e) {
    // Không dừng app nếu migration thất bại
    print('Migration failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => QuantityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CollectionsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<ThemeProvider, app_auth.AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final user = snapshot.data;
                if (user == null) {
                  return const LoginScreen();
                }

                // Kiểm tra role của user
                return FutureBuilder<String>(
                  future: authProvider.getUserRole(user.uid),
                  builder: (context, roleSnapshot) {
                    if (roleSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final role = (roleSnapshot.data ?? 'user').toLowerCase().trim();
                    final isLocked = authProvider.isLocked;
                    
                    if (isLocked) {
                      return const _LockedScreen();
                    }
                    
                    if (role == 'admin') {
                      return const AdminMainScreen();
                    }
                    
                    return const AppMainScreen();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}


class _LockedScreen extends StatelessWidget {
  const _LockedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock, size: 48, color: Colors.redAccent),
            SizedBox(height: 12),
            Text('Tài khoản của bạn đã bị khóa'),
          ],
        ),
      ),
    );
  }
}
