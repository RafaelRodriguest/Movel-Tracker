import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'providers/site_provider.dart';
import 'providers/image_provider.dart' as img;
import 'services/image_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ImageService.initialize();
  runApp(const ClaroSitesApp());
}

class ClaroSitesApp extends StatelessWidget {
  const ClaroSitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SiteProvider()),
        ChangeNotifierProvider(create: (_) => img.ImageProvider()),
      ],
      child: MaterialApp(
        title: 'Localizador de Sites - MA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surfaceLight,
            onSurface: AppColors.textLight,
            background: AppColors.backgroundLight,
          ),
          scaffoldBackgroundColor: AppColors.backgroundLight,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: AppColors.textLight,
            iconTheme: IconThemeData(color: AppColors.textLight),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFF3F4F6)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(color: AppColors.textSecondary),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.chipBgInactive,
            selectedColor: AppColors.primary,
            labelStyle: const TextStyle(
              color: AppColors.chipTextInactive,
              fontWeight: FontWeight.w500,
            ),
            side: const BorderSide(color: AppColors.chipBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
