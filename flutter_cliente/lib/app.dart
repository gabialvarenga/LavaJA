import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'screens/login_screen.dart';

class LavaJaApp extends StatelessWidget {
  const LavaJaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LavaJÁ Cliente',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bgTertiary,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.teal,
          error: AppColors.red,
          surface: AppColors.bgPrimary,
          background: AppColors.bgTertiary,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
