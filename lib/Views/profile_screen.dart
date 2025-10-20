import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/theme_provider.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Views/login_screen.dart';
import 'package:recipe_app/Views/submit_recipe_screen.dart';
import 'package:recipe_app/Views/improved_submit_recipe_screen.dart';
import 'package:recipe_app/Views/user_recipe_management_screen.dart';
import 'package:recipe_app/Views/edit_profile_screen.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header phần tài khoản
            Container(
              decoration: BoxDecoration(
                gradient: isDarkMode
                    ? LinearGradient(
                  colors: [Colors.grey[800]!, Colors.grey[900]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
                    : kProfileGradient,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Icon(
                      Iconsax.user,
                      size: 60,
                      color: Colors.grey[700],
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user != null
                        ? (user.displayName ?? user.email ?? 'Người dùng')
                        : "Đăng nhập/Đăng ký",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user?.email != null)
                    Text(
                      user!.email!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  if (user == null)
                    const Text(
                      "Khám phá thêm tính năng cá nhân hóa",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: user == null
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    }
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isDarkMode ? Colors.black : const Color(0xFF2C3E50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user == null ? Iconsax.login : Iconsax.profile_circle,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(user == null ? "Đăng nhập ngay" : "Cập nhật hồ sơ"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Danh sách các tính năng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SettingsTile(
                    icon: Iconsax.close_circle,
                    color: Colors.orange,
                    title: "Xóa quảng cáo",
                    onTap: () {},
                  ),

                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return SettingsTile(
                        icon: Iconsax.moon,
                        color: Colors.grey,
                        title: "Giao diện tối",
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) async => await themeProvider.toggleTheme(),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Iconsax.global,
                    color: Colors.green,
                    title: "Ngôn ngữ",
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Iconsax.shield_tick,
                    color: Colors.blue,
                    title: "Chính sách quyền riêng tư",
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Iconsax.message_question,
                    color: Colors.purple,
                    title: "Trợ giúp",
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Iconsax.info_circle,
                    color: Colors.teal,
                    title: "Thông tin ứng dụng",
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Nút gửi công thức và quản lý công thức (chỉ hiển thị khi đã đăng nhập)
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ImprovedSubmitRecipeScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kprimaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.add, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Gửi công thức",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserRecipeManagementScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.document_text, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Quản lý công thức",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Nút đăng xuất (chỉ hiển thị khi đã đăng nhập)
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.logout, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Đăng xuất",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDarkMode
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: trailing ??
            Icon(Iconsax.arrow_right_3,
                size: 16, color: isDarkMode ? Colors.white70 : Colors.black),
        onTap: onTap,
      ),
    );
  }
}